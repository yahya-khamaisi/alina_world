package app.jannat.alinaworld.audio

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import app.jannat.alinaworld.data.Settings
import java.util.concurrent.locks.ReentrantLock
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.floor
import kotlin.math.pow
import kotlin.math.sin

enum class SoundEffect { Jump, Petal, Shard, Stomp, PowerUp, Hurt, Bump, BrickBreak, Checkpoint, Pause, Select }

/**
 * Real-time chiptune synthesizer, ported from the Mac app: two pulse voices, a triangle bass, noise drums and
 * four sound-effect voices, mixed through a soft echo and low-pass. Everything is generated; no audio files ship.
 */
object Chiptune {
    private const val RATE = 48_000
    private var synth: ChiptuneSynth? = null
    private var thread: Thread? = null
    @Volatile private var running = false
    private var currentSong: String? = null

    fun start() {
        if (thread != null) return
        val synth = ChiptuneSynth(RATE.toDouble())
        this.synth = synth
        reloadVolumes()
        Settings.onChange { reloadVolumes() }
        running = true
        thread = Thread({
            val minBytes = AudioTrack.getMinBufferSize(RATE, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT)
            val track = AudioTrack.Builder()
                .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build())
                .setAudioFormat(AudioFormat.Builder().setSampleRate(RATE).setEncoding(AudioFormat.ENCODING_PCM_FLOAT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                .setBufferSizeInBytes(maxOf(minBytes, 4096 * 4))
                .setTransferMode(AudioTrack.MODE_STREAM)
                .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
                .build()
            val buffer = FloatArray(512)
            track.play()
            while (running) {
                synth.render(buffer, buffer.size)
                track.write(buffer, 0, buffer.size, AudioTrack.WRITE_BLOCKING)
            }
            track.stop()
            track.release()
        }, "chiptune").apply { priority = Thread.MAX_PRIORITY; start() }
    }

    fun stop() {
        running = false
        thread?.join(500)
        thread = null
        currentSong = null
    }

    /** Switches music with a short fade; passing the playing song again does nothing. */
    fun play(song: Song?) {
        if (song?.name == currentSong && song?.loops != false) return
        currentSong = if (song?.loops == false) null else song?.name
        synth?.requestSong(song)
    }

    fun play(effect: SoundEffect) { synth?.requestEffect(effect) }

    /** Lowers the music under the pause menu. */
    fun setDucked(ducked: Boolean) { synth?.requestDuck(if (ducked) 0.3f else 1f) }

    fun reloadVolumes() { synth?.requestVolumes(Settings.musicVolume, Settings.effectsVolume) }
}

class ChiptuneSynth(private val sampleRate: Double) {
    private class Voice(val level: Float, val sustain: Float) {
        var phase = 0.0
        var frequency = 0.0
        var envelope = 0f
        var gate = false
    }

    private enum class Wave { Pulse50, Pulse25, Triangle, Noise }
    private class Segment(val wave: Wave, val from: Double, val to: Double, val duration: Double, val volume: Float)
    private class EffectVoice(val segments: List<Segment> = emptyList()) {
        var index = 0
        var time = 0.0
        var phase = 0.0
        val active get() = index < segments.size
    }

    private val lock = ReentrantLock()
    private var hasPendingSong = false
    private var pendingSong: Song? = null
    private val pendingEffects = mutableListOf<List<Segment>>()
    private var pendingDuck: Float? = null
    private var pendingVolumes: Pair<Float, Float>? = null

    private var song: Song? = null
    private var hasNextSong = false
    private var nextSong: Song? = null
    private var step = -1
    private var samplesPerStep = 1.0
    private var sampleInStep = 0.0
    private val lead = Voice(0.15f, 0.55f)
    private val harmony = Voice(0.06f, 0.45f)
    private val bass = Voice(0.22f, 0.85f)
    private var kickTime = 1.0
    private var kickPhase = 0.0
    private var snareTime = 1.0
    private var hatTime = 1.0

    private var fade = 0f
    private var duck = 1f
    private var duckTarget = 1f
    private var musicVolume = 0.6f
    private var effectsVolume = 0.8f

    private val effects = Array(4) { EffectVoice() }
    private var nextEffectSlot = 0

    private val echo = FloatArray((sampleRate * 0.21).toInt())
    private var echoIndex = 0
    private var lowPass = 0f
    private var noiseState = 0x12345678
    private var lastNoise = 0f
    private val decay = (1 - exp(-1 / (0.09 * sampleRate))).toFloat()
    private val release = (1 - exp(-1 / (0.05 * sampleRate))).toFloat()

    fun requestSong(song: Song?) = locked { hasPendingSong = true; pendingSong = song }
    fun requestEffect(effect: SoundEffect) = locked { pendingEffects += segments(effect) }
    fun requestDuck(value: Float) = locked { pendingDuck = value }
    fun requestVolumes(music: Float, effects: Float) = locked { pendingVolumes = music to effects }

    private inline fun locked(block: () -> Unit) { lock.lock(); try { block() } finally { lock.unlock() } }

    private fun applyRequests() {
        if (!lock.tryLock()) return
        try {
            if (hasPendingSong) { hasNextSong = true; nextSong = pendingSong; hasPendingSong = false; pendingSong = null }
            for (segments in pendingEffects) {
                effects[nextEffectSlot] = EffectVoice(segments)
                nextEffectSlot = (nextEffectSlot + 1) % effects.size
            }
            pendingEffects.clear()
            pendingDuck?.let { duckTarget = it; pendingDuck = null }
            pendingVolumes?.let { musicVolume = it.first; effectsVolume = it.second; pendingVolumes = null }
        } finally {
            lock.unlock()
        }
    }

    fun render(out: FloatArray, frames: Int) {
        applyRequests()
        for (i in 0 until frames) out[i] = nextSample()
    }

    private fun nextSample(): Float {
        // Fade out the old song before swapping, then fade the new one in.
        if (hasNextSong) {
            fade -= 1 / (0.25f * sampleRate.toFloat())
            if (fade <= 0 || song == null) {
                fade = 0f
                startSong(nextSong)
                hasNextSong = false
                nextSong = null
            }
        } else if (song != null && fade < 1) {
            fade = minOf(1f, fade + 1 / (0.4f * sampleRate.toFloat()))
        }
        duck += (duckTarget - duck) * 0.0005f

        var music = 0f
        song?.let { s ->
            sampleInStep += 1
            if (sampleInStep >= samplesPerStep) {
                sampleInStep -= samplesPerStep
                advance(s)
            }
            music = voiceSample(lead, Wave.Pulse25) + voiceSample(harmony, Wave.Pulse25) +
                voiceSample(bass, Wave.Triangle) + drumSample()
        }

        val echoed = echo[echoIndex]
        echo[echoIndex] = music + echoed * 0.3f
        echoIndex = (echoIndex + 1) % echo.size
        val musicBus = (music + echoed * 0.22f) * fade * duck * musicVolume

        var sfx = 0f
        for (e in effects) if (e.active) sfx += effectSample(e)

        val mixed = musicBus + sfx * effectsVolume
        lowPass += (mixed - lowPass) * 0.5f
        val boosted = lowPass * 2.2f
        return boosted / (1 + abs(boosted))
    }

    private fun startSong(newSong: Song?) {
        song = newSong
        step = -1
        sampleInStep = 0.0
        lead.gate = false; harmony.gate = false; bass.gate = false
        if (newSong != null) {
            samplesPerStep = sampleRate * 60 / newSong.bpm / 2
            sampleInStep = samplesPerStep
        }
    }

    private fun advance(s: Song) {
        step++
        if (step >= s.length) {
            if (s.loops) step = 0 else {
                lead.gate = false; harmony.gate = false; bass.gate = false
                song = null
                return
            }
        }
        trigger(lead, s.lead, step)
        trigger(harmony, s.harmony, step)
        trigger(bass, s.bass, step)
        if (step < s.drums.size) when (s.drums[step]) {
            'k' -> { kickTime = 0.0; kickPhase = 0.0 }
            's' -> snareTime = 0.0
            'h' -> hatTime = 0.0
        }
    }

    private fun trigger(voice: Voice, track: IntArray, step: Int) {
        if (step >= track.size) return
        val token = track[step]
        if (token > 0) {
            voice.frequency = 440 * 2.0.pow((token - 69) / 12.0)
            voice.gate = true
            voice.envelope = 1f
        } else if (token == Song.REST) {
            voice.gate = false
        }
    }

    private fun voiceSample(voice: Voice, wave: Wave): Float {
        if (voice.gate) voice.envelope += (voice.sustain - voice.envelope) * decay
        else voice.envelope -= voice.envelope * release
        if (voice.envelope <= 0.0005f) return 0f
        voice.phase += voice.frequency / sampleRate
        voice.phase -= floor(voice.phase)
        return oscillator(wave, voice.phase) * voice.envelope * voice.level
    }

    private fun drumSample(): Float {
        val dt = 1 / sampleRate
        var out = 0f
        if (kickTime < 0.16) {
            val frequency = 48 + 110 * exp(-kickTime * 32)
            kickPhase += frequency * dt
            out += (sin(2 * Math.PI * kickPhase) * exp(-kickTime * 18)).toFloat() * 0.42f
            kickTime += dt
        }
        if (snareTime < 0.18) {
            out += noise() * exp(-snareTime * 24).toFloat() * 0.16f
            snareTime += dt
        }
        if (hatTime < 0.05) {
            val n = noise()
            out += (n - lastNoise) * exp(-hatTime * 90).toFloat() * 0.05f
            lastNoise = n
            hatTime += dt
        }
        return out
    }

    private fun effectSample(v: EffectVoice): Float {
        val segment = v.segments[v.index]
        val progress = v.time / segment.duration
        val frequency = segment.from * (segment.to / segment.from).pow(progress)
        v.phase += frequency / sampleRate
        v.phase -= floor(v.phase)
        val envelope = segment.volume * (1 - 0.7f * progress.toFloat())
        val sample = oscillator(segment.wave, v.phase) * envelope
        v.time += 1 / sampleRate
        if (v.time >= segment.duration) { v.time = 0.0; v.index++ }
        return sample * 0.5f
    }

    private fun oscillator(wave: Wave, phase: Double): Float = when (wave) {
        Wave.Pulse50 -> if (phase < 0.5) 0.5f else -0.5f
        Wave.Pulse25 -> if (phase < 0.25) 0.5f else -0.5f
        Wave.Triangle -> (4 * abs(phase - 0.5) - 1).toFloat()
        Wave.Noise -> noise() * 0.6f
    }

    private fun noise(): Float {
        noiseState = noiseState xor (noiseState shl 13)
        noiseState = noiseState xor (noiseState ushr 17)
        noiseState = noiseState xor (noiseState shl 5)
        return noiseState.toFloat() / Int.MAX_VALUE
    }

    private fun segments(effect: SoundEffect): List<Segment> {
        fun tone(wave: Wave, from: Double, to: Double? = null, duration: Double, volume: Float = 0.5f) =
            Segment(wave, from, to ?: from, duration, volume)
        return when (effect) {
            SoundEffect.Jump -> listOf(tone(Wave.Pulse25, 320.0, 760.0, 0.13, 0.45f))
            SoundEffect.Petal -> listOf(tone(Wave.Pulse50, 988.0, null, 0.05, 0.35f), tone(Wave.Pulse50, 1319.0, null, 0.12, 0.35f))
            SoundEffect.Shard -> listOf(784.0, 988.0, 1175.0, 1568.0, 1976.0).map { tone(Wave.Pulse25, it, null, 0.06, 0.45f) }
            SoundEffect.Stomp -> listOf(tone(Wave.Noise, 200.0, null, 0.04, 0.6f), tone(Wave.Pulse50, 260.0, 90.0, 0.1, 0.5f))
            SoundEffect.PowerUp -> listOf(523.0, 659.0, 784.0, 1047.0, 1319.0, 1568.0).map { tone(Wave.Pulse25, it, null, 0.055, 0.45f) }
            SoundEffect.Hurt -> listOf(tone(Wave.Pulse50, 520.0, 120.0, 0.32, 0.5f))
            SoundEffect.Bump -> listOf(tone(Wave.Triangle, 180.0, 110.0, 0.09, 0.8f))
            SoundEffect.BrickBreak -> listOf(tone(Wave.Noise, 300.0, null, 0.16, 0.7f))
            SoundEffect.Checkpoint -> listOf(tone(Wave.Pulse25, 784.0, null, 0.08, 0.45f), tone(Wave.Pulse25, 1047.0, null, 0.18, 0.45f))
            SoundEffect.Pause -> listOf(tone(Wave.Pulse50, 880.0, null, 0.05, 0.3f), tone(Wave.Pulse50, 660.0, null, 0.09, 0.3f))
            SoundEffect.Select -> listOf(tone(Wave.Pulse25, 1047.0, null, 0.04, 0.25f))
        }
    }
}
