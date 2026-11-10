import AVFoundation
import Foundation

enum SoundEffect {
    case jump, doubleJump, spring, petal, shard, stomp, powerUp, hurt, bump, brickBreak, checkpoint, pause, select
}

/// Real-time chiptune synthesizer: two pulse voices, a triangle bass, noise drums and four
/// sound-effect voices, mixed through a soft echo and low-pass so it stays warm rather than shrill.
/// Everything is generated at runtime — the game ships no audio files.
final class ChiptuneEngine {
    static let shared = ChiptuneEngine()

    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private var synth: ChiptuneSynth?
    private var currentSongName: String?
    private var observers: [NSObjectProtocol] = []

    func start() {
        guard source == nil else { return }
        let rate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let sampleRate = rate > 0 ? rate : 48_000
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        let synth = ChiptuneSynth(sampleRate: sampleRate)
        self.synth = synth
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let first = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            synth.render(into: first, frames: Int(frameCount))
            for buffer in buffers.dropFirst() {
                buffer.mData?.copyMemory(from: first, byteCount: Int(frameCount) * MemoryLayout<Float>.size)
            }
            return noErr
        }
        engine.attach(node)
        do {
            try engine.connectNode(node, to: engine.mainMixerNode, format: format)
        } catch {
            engine.detach(node)
            return
        }
        source = node
        reloadVolumes()
        launch()

        observers.append(NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.reloadVolumes() })
        observers.append(NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in self?.launch() })
    }

    private func launch() {
        guard !engine.isRunning else { return }
        engine.prepare()
        try? engine.start()
    }

    /// Switches music with a short fade; passing the playing song again does nothing.
    func play(_ song: Song?) {
        guard song?.name != currentSongName || song?.loops == false else { return }
        currentSongName = song?.loops == false ? nil : song?.name
        synth?.request(song: song)
    }

    func play(_ effect: SoundEffect) {
        synth?.request(effect: effect)
    }

    /// Lowers the music under the pause menu.
    func setDucked(_ ducked: Bool) {
        synth?.request(duck: ducked ? 0.3 : 1)
    }

    func reloadVolumes() {
        let defaults = UserDefaults.standard
        let music = defaults.object(forKey: SettingsKey.musicVolume) as? Double ?? 0.6
        let effects = defaults.object(forKey: SettingsKey.effectsVolume) as? Double ?? 0.8
        synth?.request(music: Float(music), effects: Float(effects))
    }
}

// MARK: - Synth (render thread; internal so the soundtrack can be rendered offline)

final class ChiptuneSynth {
    private struct Voice {
        var phase: Double = 0
        var frequency: Double = 0
        var envelope: Float = 0
        var gate = false
        var level: Float
        var sustain: Float
        var wave: Instrument.Wave = .pulse25
        var decayCoefficient: Float = 0
        var vibrato: Double = 0

        init(level: Float, sustain: Float) {
            self.level = level
            self.sustain = sustain
        }
    }

    private enum Wave { case pulse50, pulse25, triangle, noise, sine, bell, steel }

    private struct Segment {
        let wave: Wave
        let from: Double
        let to: Double
        let duration: Double
        let volume: Float
    }

    private struct EffectVoice {
        var segments: [Segment] = []
        var index = 0
        var time: Double = 0
        var phase: Double = 0
        var active: Bool { index < segments.count }
    }

    private let sampleRate: Double
    private let lock = NSLock()

    // Requests from the main thread, applied at the start of the next render block.
    private var pendingSong: Song??
    private var pendingEffects: [[Segment]] = []
    private var pendingDuck: Float?
    private var pendingVolumes: (Float, Float)?

    private var song: Song?
    private var nextSong: Song??
    private var step = -1
    private var samplesPerStep: Double = 1
    private var sampleInStep: Double = 0
    private var lead = Voice(level: 0.15, sustain: 0.55)
    private var harmony = Voice(level: 0.06, sustain: 0.45)
    private var bass: Voice = {
        var voice = Voice(level: 0.22, sustain: 0.85)
        voice.wave = .triangle
        return voice
    }()
    private var kickTime: Double = 1
    private var kickPhase: Double = 0
    private var snareTime: Double = 1
    private var hatTime: Double = 1
    private var drumLevel: Float = 1
    private var songGain: Float = 1
    private var swing: Double = 0
    private var baseSamplesPerStep: Double = 1
    private var vibratoTime: Double = 0

    private var fade: Float = 0
    private var duck: Float = 1
    private var duckTarget: Float = 1
    private var musicVolume: Float = 0.6
    private var effectsVolume: Float = 0.8

    private var effects = [EffectVoice](repeating: EffectVoice(), count: 4)
    private var nextEffectSlot = 0

    private var echo: [Float]
    private var echoIndex = 0
    private var lowPass: Float = 0
    private var noiseState: UInt32 = 0x1234_5678
    private var lastNoise: Float = 0
    private let decayCoefficient: Float
    private let releaseCoefficient: Float

    init(sampleRate: Double) {
        self.sampleRate = sampleRate
        echo = [Float](repeating: 0, count: Int(sampleRate * 0.21))
        decayCoefficient = Float(1 - exp(-1 / (0.09 * sampleRate)))
        releaseCoefficient = Float(1 - exp(-1 / (0.05 * sampleRate)))
    }

    // MARK: Requests

    func request(song: Song?) {
        lock.lock(); pendingSong = .some(song); lock.unlock()
    }

    func request(effect: SoundEffect) {
        lock.lock(); pendingEffects.append(Self.segments(for: effect)); lock.unlock()
    }

    func request(duck: Float) {
        lock.lock(); pendingDuck = duck; lock.unlock()
    }

    func request(music: Float, effects: Float) {
        lock.lock(); pendingVolumes = (music, effects); lock.unlock()
    }

    private func applyRequests() {
        guard lock.try() else { return }
        if let pending = pendingSong {
            nextSong = .some(pending)
            pendingSong = nil
        }
        for segments in pendingEffects {
            effects[nextEffectSlot] = EffectVoice(segments: segments)
            nextEffectSlot = (nextEffectSlot + 1) % effects.count
        }
        pendingEffects.removeAll(keepingCapacity: true)
        if let duck = pendingDuck { duckTarget = duck; pendingDuck = nil }
        if let volumes = pendingVolumes { (musicVolume, effectsVolume) = volumes; pendingVolumes = nil }
        lock.unlock()
    }

    // MARK: Render

    func render(into output: UnsafeMutablePointer<Float>, frames: Int) {
        applyRequests()
        for i in 0..<frames {
            output[i] = nextSample()
        }
    }

    private func nextSample() -> Float {
        // Fade out the old song before swapping, then fade the new one in.
        if let pending = nextSong {
            fade -= 1 / Float(0.25 * sampleRate)
            if fade <= 0 || song == nil {
                fade = 0
                startSong(pending)
                nextSong = nil
            }
        } else if song != nil && fade < 1 {
            fade = min(1, fade + 1 / Float(0.4 * sampleRate))
        }
        duck += (duckTarget - duck) * 0.0005

        var music: Float = 0
        if let song {
            sampleInStep += 1
            if sampleInStep >= samplesPerStep {
                sampleInStep -= samplesPerStep
                advance(song)
            }
            vibratoTime += 1 / sampleRate
            music = voiceSample(&lead)
                + voiceSample(&harmony)
                + voiceSample(&bass)
                + drumSample() * drumLevel
        }

        let echoed = echo[echoIndex]
        echo[echoIndex] = music + echoed * 0.3
        echoIndex = (echoIndex + 1) % echo.count
        let musicBus = (music + echoed * 0.22) * fade * duck * musicVolume * songGain

        var sfx: Float = 0
        for i in effects.indices where effects[i].active {
            sfx += effectSample(&effects[i])
        }

        let mixed = musicBus + sfx * effectsVolume
        lowPass += (mixed - lowPass) * 0.4
        let boosted = lowPass * 2.2
        return boosted / (1 + abs(boosted))
    }

    private func startSong(_ newSong: Song?) {
        song = newSong
        step = -1
        sampleInStep = 0
        lead.gate = false
        harmony.gate = false
        bass.gate = false
        if let newSong {
            baseSamplesPerStep = sampleRate * 60 / newSong.bpm / 2
            samplesPerStep = baseSamplesPerStep
            sampleInStep = samplesPerStep
            drumLevel = newSong.drumLevel
            songGain = newSong.gain
            swing = newSong.swing
            configure(&lead, newSong.leadVoice)
            configure(&harmony, newSong.harmonyVoice)
        }
    }

    private func configure(_ voice: inout Voice, _ instrument: Instrument) {
        voice.wave = instrument.wave
        voice.level = instrument.level
        voice.sustain = instrument.sustain
        voice.vibrato = instrument.vibrato
        voice.decayCoefficient = Float(1 - exp(-1 / (instrument.decay * sampleRate)))
    }

    private func advance(_ song: Song) {
        step += 1
        // Swing: on-beat eighths run long, off-beat ones short.
        samplesPerStep = baseSamplesPerStep * (step % 2 == 0 ? 1 + swing : 1 - swing)
        if step >= song.length {
            if song.loops {
                step = 0
            } else {
                lead.gate = false
                harmony.gate = false
                bass.gate = false
                self.song = nil
                return
            }
        }
        trigger(&lead, song.lead, step)
        trigger(&harmony, song.harmony, step)
        trigger(&bass, song.bass, step)
        if step < song.drums.count {
            switch song.drums[step] {
            case "k": kickTime = 0; kickPhase = 0
            case "s": snareTime = 0
            case "h": hatTime = 0
            default: break
            }
        }
    }

    private func trigger(_ voice: inout Voice, _ track: [Int], _ step: Int) {
        guard step < track.count else { return }
        let token = track[step]
        if token > 0 {
            voice.frequency = 440 * pow(2, Double(token - 69) / 12)
            voice.gate = true
            voice.envelope = 1
        } else if token == Song.rest {
            voice.gate = false
        }
    }

    private func voiceSample(_ voice: inout Voice) -> Float {
        if voice.gate {
            let coefficient = voice.decayCoefficient > 0 ? voice.decayCoefficient : decayCoefficient
            voice.envelope += (voice.sustain - voice.envelope) * coefficient
        } else {
            voice.envelope -= voice.envelope * releaseCoefficient
        }
        guard voice.envelope > 0.0005 else { return 0 }
        let wobble = voice.vibrato > 0 ? 1 + voice.vibrato * sin(2 * .pi * 5.2 * vibratoTime) : 1
        voice.phase += voice.frequency * wobble / sampleRate
        voice.phase -= voice.phase.rounded(.down)
        let wave: Wave
        switch voice.wave {
        case .pulse50: wave = .pulse50
        case .pulse25: wave = .pulse25
        case .triangle: wave = .triangle
        case .sine: wave = .sine
        case .bell: wave = .bell
        case .steel: wave = .steel
        }
        return oscillator(wave, phase: voice.phase) * voice.envelope * voice.level
    }

    private func drumSample() -> Float {
        let dt = 1 / sampleRate
        var out: Float = 0
        if kickTime < 0.16 {
            let frequency = 48 + 110 * exp(-kickTime * 32)
            kickPhase += frequency * dt
            out += Float(sin(2 * .pi * kickPhase) * exp(-kickTime * 18)) * 0.42
            kickTime += dt
        }
        if snareTime < 0.18 {
            out += noise() * Float(exp(-snareTime * 24)) * 0.16
            snareTime += dt
        }
        if hatTime < 0.05 {
            let n = noise()
            out += (n - lastNoise) * Float(exp(-hatTime * 90)) * 0.05
            lastNoise = n
            hatTime += dt
        }
        return out
    }

    private func effectSample(_ voice: inout EffectVoice) -> Float {
        let segment = voice.segments[voice.index]
        let progress = voice.time / segment.duration
        let frequency = segment.from * pow(segment.to / segment.from, progress)
        voice.phase += frequency / sampleRate
        voice.phase -= voice.phase.rounded(.down)
        let envelope = segment.volume * Float(1 - 0.7 * progress)
        let sample = oscillator(segment.wave, phase: voice.phase) * envelope
        voice.time += 1 / sampleRate
        if voice.time >= segment.duration {
            voice.time = 0
            voice.index += 1
        }
        return sample * 0.5
    }

    private func oscillator(_ wave: Wave, phase: Double) -> Float {
        switch wave {
        case .pulse50: return phase < 0.5 ? 0.5 : -0.5
        case .pulse25: return phase < 0.25 ? 0.5 : -0.5
        case .triangle: return Float(4 * abs(phase - 0.5) - 1)
        case .noise: return noise() * 0.6
        case .sine: return Float(sin(2 * .pi * phase)) * 0.8
        case .bell:
            // Fundamental plus a quiet octave, like a music box tine.
            return Float(sin(2 * .pi * phase) * 0.65 + sin(4 * .pi * phase) * 0.25)
        case .steel:
            return Float(sin(2 * .pi * phase) * 0.6 + sin(6 * .pi * phase) * 0.25 + sin(4 * .pi * phase) * 0.1)
        }
    }

    private func noise() -> Float {
        noiseState ^= noiseState << 13
        noiseState ^= noiseState >> 17
        noiseState ^= noiseState << 5
        return Float(Int32(bitPattern: noiseState)) / Float(Int32.max)
    }

    // MARK: Effects

    private static func segments(for effect: SoundEffect) -> [Segment] {
        func tone(_ wave: Wave, _ from: Double, _ to: Double? = nil, _ duration: Double, _ volume: Float = 0.5) -> Segment {
            Segment(wave: wave, from: from, to: to ?? from, duration: duration, volume: volume)
        }
        switch effect {
        case .jump:
            return [tone(.pulse25, 320, 760, 0.13, 0.45)]
        case .doubleJump:
            return [tone(.sine, 660, 1320, 0.1, 0.5), tone(.sine, 1320, 1760, 0.08, 0.35)]
        case .spring:
            return [tone(.triangle, 220, 880, 0.18, 0.7)]
        case .petal:
            return [tone(.pulse50, 988, nil, 0.05, 0.35), tone(.pulse50, 1319, nil, 0.12, 0.35)]
        case .shard:
            return [784, 988, 1175, 1568, 1976].map { tone(.pulse25, $0, nil, 0.06, 0.45) }
        case .stomp:
            return [tone(.noise, 200, nil, 0.04, 0.6), tone(.pulse50, 260, 90, 0.1, 0.5)]
        case .powerUp:
            return [523, 659, 784, 1047, 1319, 1568].map { tone(.pulse25, $0, nil, 0.055, 0.45) }
        case .hurt:
            return [tone(.pulse50, 520, 120, 0.32, 0.5)]
        case .bump:
            return [tone(.triangle, 180, 110, 0.09, 0.8)]
        case .brickBreak:
            return [tone(.noise, 300, nil, 0.16, 0.7)]
        case .checkpoint:
            return [tone(.pulse25, 784, nil, 0.08, 0.45), tone(.pulse25, 1047, nil, 0.18, 0.45)]
        case .pause:
            return [tone(.pulse50, 880, nil, 0.05, 0.3), tone(.pulse50, 660, nil, 0.09, 0.3)]
        case .select:
            return [tone(.pulse25, 1047, nil, 0.04, 0.25)]
        }
    }
}
