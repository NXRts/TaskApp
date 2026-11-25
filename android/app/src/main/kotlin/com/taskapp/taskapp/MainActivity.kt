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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SETTINGS_CHANNEL = "com.taskapp.taskapp/settings"
    private val AMBIENT_PCM_CHANNEL = "com.taskapp.taskapp/ambient_pcm"
    private var ambientAudioTrack: AudioTrack? = null
    private var ambientSampleRate: Int = 16000

    @Synchronized
    private fun ensureAmbientAudioTrack(sampleRate: Int): AudioTrack {
        val existing = ambientAudioTrack
        if (existing != null && existing.state == AudioTrack.STATE_INITIALIZED && ambientSampleRate == sampleRate) {
            if (existing.playState != AudioTrack.PLAYSTATE_PLAYING) {
                existing.play()
            }
            return existing
        }
        stopAndReleaseAmbientAudioTrack()
        ambientSampleRate = sampleRate

        val minBuf = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        ).coerceAtLeast(sampleRate)

        val bufferSizeBytes = (sampleRate * 2).coerceAtLeast(minBuf * 2)
        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setBufferSizeInBytes(bufferSizeBytes)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()

        track.play()
        ambientAudioTrack = track
        return track
    }

    @Synchronized
    private fun writeAmbientPcmChunk(pcmBytes: ByteArray, sampleRate: Int): Int {
        val track = ensureAmbientAudioTrack(sampleRate)
        return track.write(pcmBytes, 0, pcmBytes.size, AudioTrack.WRITE_NON_BLOCKING)
    }

    @Synchronized
    private fun stopAndReleaseAmbientAudioTrack() {
        val track = ambientAudioTrack
        ambientAudioTrack = null
        if (track != null) {
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
    }

    override fun onDestroy() {
        stopAndReleaseAmbientAudioTrack()
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
                "start" -> {
                    val sampleRate = call.argument<Int>("sampleRate") ?: 16000
                    try {
                        ensureAmbientAudioTrack(sampleRate)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AUDIO_TRACK_START_ERR", e.message, null)
                    }
                }
                "write" -> {
                    val bytes = call.argument<ByteArray>("pcm")
                    val sampleRate = call.argument<Int>("sampleRate") ?: 16000
                    if (bytes == null || bytes.isEmpty()) {
                        result.success(0)
                        return@setMethodCallHandler
                    }
                    try {
                        val written = writeAmbientPcmChunk(bytes, sampleRate)
                        result.success(written)
                    } catch (e: Exception) {
                        result.error("AUDIO_TRACK_WRITE_ERR", e.message, null)
                    }
                }
                "stop" -> {
                    stopAndReleaseAmbientAudioTrack()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
