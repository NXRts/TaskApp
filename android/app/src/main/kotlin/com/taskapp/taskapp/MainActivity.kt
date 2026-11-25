package com.taskapp.taskapp

import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    private val SETTINGS_CHANNEL = "com.taskapp.taskapp/settings"
    private val AMBIENT_PCM_CHANNEL = "com.taskapp.taskapp/ambient_pcm"
    private val ambientSampleRate = 16000

    private val trackSamplesCache = ConcurrentHashMap<String, ShortArray>()
    private val trackPlaying = ConcurrentHashMap<String, Boolean>()
    private val trackVolumes = ConcurrentHashMap<String, Double>()
    private val trackCurrentGains = ConcurrentHashMap<String, Double>()
    private val trackCursors = ConcurrentHashMap<String, Int>()
    @Volatile
    private var masterVolume: Double = 1.0
    @Volatile
    private var mixerRunning: Boolean = false
    private var mixerThread: Thread? = null
    private var ambientAudioTrack: AudioTrack? = null

    private fun loadTrackPcmSamples(trackId: String, assetPath: String): ShortArray? {
        trackSamplesCache[trackId]?.let { return it }
        return try {
            val loader = FlutterInjector.instance().flutterLoader()
            val lookupKey = loader.getLookupKeyForAsset(assetPath)
            assets.open(lookupKey).use { input ->
                val rawBytes = input.readBytes()
                if (rawBytes.size <= 44) return null
                val pcmByteLen = rawBytes.size - 44
                val sampleCount = pcmByteLen / 2
                val shorts = ShortArray(sampleCount)
                ByteBuffer.wrap(rawBytes, 44, pcmByteLen)
                    .order(ByteOrder.LITTLE_ENDIAN)
                    .asShortBuffer()
                    .get(shorts)
                trackSamplesCache[trackId] = shorts
                shorts
            }
        } catch (e: Exception) {
            null
        }
    }

    @Synchronized
    private fun syncNativeAmbientMixer(
        tracksData: List<Map<String, Any?>>,
        masterVol: Double
    ) {
        masterVolume = masterVol.coerceIn(0.0, 1.0)
        var anyActive = false

        for (item in tracksData) {
            val id = item["id"] as? String ?: continue
            val assetPath = item["assetPath"] as? String ?: "assets/sounds/ambient_$id.wav"
            val playing = item["playing"] as? Boolean ?: false
            val vol = (item["volume"] as? Number)?.toDouble()?.coerceIn(0.0, 1.0) ?: 0.5

            trackPlaying[id] = playing
            trackVolumes[id] = vol
            if (!trackCurrentGains.containsKey(id)) {
                trackCurrentGains[id] = vol * masterVolume
            }
            if (!trackCursors.containsKey(id)) {
                trackCursors[id] = 0
            }
            if (playing) {
                anyActive = true
                loadTrackPcmSamples(id, assetPath)
            }
        }

        if (anyActive) {
            startNativeMixerThreadIfNeeded()
        } else {
            stopNativeMixerThread()
        }
    }

    @Synchronized
    private fun startNativeMixerThreadIfNeeded() {
        if (mixerRunning && mixerThread?.isAlive == true) return
        stopNativeMixerThread()
        mixerRunning = true

        val thread = Thread({
            val minBuf = AudioTrack.getMinBufferSize(
                ambientSampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            ).coerceAtLeast(ambientSampleRate)
            val bufferSizeBytes = (ambientSampleRate * 2).coerceAtLeast(minBuf * 2)

            val track = try {
                AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(ambientSampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build()
                    )
                    .setBufferSizeInBytes(bufferSizeBytes)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()
            } catch (_: Exception) {
                mixerRunning = false
                return@Thread
            }

            synchronized(this@MainActivity) {
                ambientAudioTrack = track
            }

            try {
                track.play()
                val chunkSamples = 640 // 40ms @ 16000Hz
                val outBuffer = ShortArray(chunkSamples)
                val crossfadeWindow = (ambientSampleRate * 2.5).roundToInt() // 2.5s seamless circular crossfade

                while (mixerRunning) {
                    var anyPlayingNow = false
                    for (entry in trackPlaying.entries) {
                        if (entry.value) {
                            anyPlayingNow = true
                            break
                        }
                    }
                    if (!anyPlayingNow) {
                        Thread.sleep(25)
                        continue
                    }

                    for (i in 0 until chunkSamples) {
                        var mixed = 0.0
                        for ((id, isPlay) in trackPlaying) {
                            if (!isPlay) continue
                            val samples = trackSamplesCache[id] ?: continue
                            val totalSamples = samples.size
                            if (totalSamples <= 0) continue

                            val fadeLen = min(crossfadeWindow, totalSamples / 4)
                            val effectiveLoopLen = (totalSamples - fadeLen).coerceAtLeast(1)

                            val targetGain = (trackVolumes[id] ?: 0.5) * masterVolume
                            val prevGain = trackCurrentGains[id] ?: targetGain
                            val curGain = prevGain + 0.003 * (targetGain - prevGain)
                            trackCurrentGains[id] = curGain

                            var cursor = (trackCursors[id] ?: 0) % effectiveLoopLen
                            val sampleVal: Double
                            if (fadeLen > 0 && cursor >= effectiveLoopLen - fadeLen) {
                                // Dual-head equal-power circular crossfade between tail and head
                                val fadePos = cursor - (effectiveLoopLen - fadeLen)
                                val phase = (fadePos.toDouble() / fadeLen.toDouble()) * (PI * 0.5)
                                val tailWeight = cos(phase)
                                val headWeight = sin(phase)
                                val tailSample = samples[fadeLen + cursor].toDouble()
                                val headSample = samples[fadePos].toDouble()
                                sampleVal = tailSample * tailWeight + headSample * headWeight
                            } else {
                                sampleVal = samples[fadeLen + cursor].toDouble()
                            }

                            cursor++
                            if (cursor >= effectiveLoopLen) cursor = 0
                            trackCursors[id] = cursor

                            mixed += sampleVal * curGain
                        }
                        val clamped = mixed.roundToInt().coerceIn(-32767, 32767)
                        outBuffer[i] = clamped.toShort()
                    }

                    track.write(outBuffer, 0, chunkSamples, AudioTrack.WRITE_BLOCKING)
                }
            } catch (_: InterruptedException) {
            } catch (_: Exception) {
            } finally {
                try {
                    if (track.playState == AudioTrack.PLAYSTATE_PLAYING) {
                        track.pause()
                        track.flush()
                    }
                } catch (_: Exception) {}
                try {
                    track.release()
                } catch (_: Exception) {}
            }
        }, "TaskAppAmbientMixerThread").apply {
            isDaemon = true
            priority = Thread.MAX_PRIORITY
        }

        mixerThread = thread
        thread.start()
    }

    @Synchronized
    private fun stopNativeMixerThread() {
        mixerRunning = false
        for (key in trackPlaying.keys) {
            trackPlaying[key] = false
        }
        val track = ambientAudioTrack
        ambientAudioTrack = null
        if (track != null) {
            try {
                if (track.playState == AudioTrack.PLAYSTATE_PLAYING) {
                    track.pause()
                    track.flush()
                }
            } catch (_: Exception) {}
        }
        val t = mixerThread
        mixerThread = null
        if (t != null && t.isAlive) {
            try {
                t.interrupt()
            } catch (_: Exception) {}
        }
    }

    override fun onDestroy() {
        stopNativeMixerThread()
        super.onDestroy()
    }

    // Direct static references so R8 and AAPT2 never strip notification resources in release builds
    private fun keepNotificationResources() {
        val icon = R.drawable.app_icon
        val notif = R.drawable.ic_notification
        val sound = R.raw.task_alarm
        if (icon == 0 || notif == 0 || sound == 0) {
            println("Notification resources kept")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        keepNotificationResources()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    try {
                        val intent = Intent()
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                            intent.putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            intent.putExtra("app_package", packageName)
                            intent.putExtra("app_uid", applicationInfo.uid)
                        } else {
                            intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                            intent.data = Uri.fromParts("package", packageName, null)
                        }
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            fallbackIntent.data = Uri.fromParts("package", packageName, null)
                            fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(fallbackIntent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:$packageName")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                                return@setMethodCallHandler
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("ERROR", e2.message, null)
                        }
                    }
                }
                "openExternalUrl" -> {
                    val url = call.argument<String>("url")?.trim()
                    if (url.isNullOrEmpty() || (!url.startsWith("https://") && !url.startsWith("http://"))) {
                        result.error("INVALID_URL", "URL harus menggunakan skema http atau https", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AMBIENT_PCM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncState" -> {
                    @Suppress("UNCHECKED_CAST")
                    val tracks = call.argument<List<Map<String, Any?>>>("tracks") ?: emptyList()
                    val masterVol = call.argument<Double>("masterVolume") ?: 1.0
                    try {
                        syncNativeAmbientMixer(tracks, masterVol)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("MIXER_SYNC_ERR", e.message, null)
                    }
                }
                "stop" -> {
                    stopNativeMixerThread()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
