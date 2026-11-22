import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

/// Available offline ambient soundscape tracks for Pomodoro focus sessions.
enum AmbientSoundType {
  off(
    id: 'off',
    label: 'Hening',
    subtitle: 'Tanpa suara latar ambient',
    icon: Icons.volume_off_outlined,
    assetPath: null,
  ),
  gentleRain(
    id: 'gentle_rain',
    label: 'Hujan Lembut',
    subtitle: 'Gentle Rain • Rintik hujan penenang fokus',
    icon: Icons.water_drop_outlined,
    assetPath: 'sounds/ambient_gentle_rain.wav',
  ),
  quietStudy(
    id: 'quiet_study',
    label: 'Suasana Kafe',
    subtitle: 'Quiet Study • Derau hangat perpustakaan & kafe',
    icon: Icons.local_cafe_outlined,
    assetPath: 'sounds/ambient_quiet_study.wav',
  ),
  whiteNoise(
    id: 'white_noise',
    label: 'Ombak Malam',
    subtitle: 'White Noise • Debur ombak malam penutup bising',
    icon: Icons.waves_outlined,
    assetPath: 'sounds/ambient_night_waves.wav',
  );

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String? assetPath;

  const AmbientSoundType({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.assetPath,
  });

  static AmbientSoundType fromId(String? id) {
    for (final value in AmbientSoundType.values) {
      if (value.id == id) return value;
    }
    return AmbientSoundType.off;
  }
}

/// Pure-Dart procedural 16-bit PCM WAV synthesizer and volume scaler for
/// offline ambient soundscapes with seamless circular crossfade boundaries.
class AmbientSoundGenerator {
  static const int defaultSampleRate = 16000;

  /// Generates a valid 16-bit mono RIFF/WAVE byte buffer with a seamless loop seam.
  static Uint8List generateWavBytes(
    AmbientSoundType type, {
    int sampleRate = defaultSampleRate,
    int durationSeconds = 3,
    double volumeScale = 1.0,
  }) {
    final totalSamples = math.max(sampleRate, sampleRate * durationSeconds);
    final fadeSamples = math.min(totalSamples ~/ 4, (sampleRate * 0.35).round());
    final rawLength = totalSamples + fadeSamples;
    final raw = Float64List(rawLength);
    final rng = math.Random(type.index * 101 + 7);
    final gain = volumeScale.clamp(0.0, 1.0);

    if (type == AmbientSoundType.gentleRain) {
      double lp1 = 0.0;
      double lp2 = 0.0;
      double dropletEnv = 0.0;
      for (int i = 0; i < rawLength; i++) {
        final white = rng.nextDouble() * 2.0 - 1.0;
        lp1 = 0.72 * lp1 + 0.28 * white;
        lp2 = 0.55 * lp2 + 0.45 * lp1;
        if (rng.nextDouble() < 0.018) {
          dropletEnv = math.min(1.0, dropletEnv + 0.15 + rng.nextDouble() * 0.2);
        }
        dropletEnv *= 0.965;
        final patter = (white - lp1) * dropletEnv * 0.45;
        final t = (i % totalSamples) / totalSamples;
        final breeze = 0.88 + 0.12 * math.sin(2.0 * math.pi * t);
        raw[i] = (lp2 * 0.42 + patter) * breeze * gain;
      }
    } else if (type == AmbientSoundType.quietStudy) {
      double brown = 0.0;
      double midLp = 0.0;
      for (int i = 0; i < rawLength; i++) {
        final white = rng.nextDouble() * 2.0 - 1.0;
        brown = (brown + 0.04 * white) * 0.975;
        midLp = 0.86 * midLp + 0.14 * white;
        final midBand = midLp - brown * 0.6;
        final t = (i % totalSamples) / totalSamples;
        final murmurMod = 0.78 +
            0.12 * math.sin(2.0 * math.pi * t + 0.4) +
            0.07 * math.sin(4.0 * math.pi * t + 1.2) +
            0.05 * math.cos(6.0 * math.pi * t);
        raw[i] = (brown * 0.38 + midBand * 0.22 * murmurMod) * 0.9 * gain;
      }
    } else if (type == AmbientSoundType.whiteNoise) {
      double surfLp = 0.0;
      double deepLp = 0.0;
      for (int i = 0; i < rawLength; i++) {
        final white = rng.nextDouble() * 2.0 - 1.0;
        final t = (i % totalSamples) / totalSamples;
        final swell = 0.5 - 0.38 * math.cos(2.0 * math.pi * t);
        final shimmer = 0.06 * math.sin(4.0 * math.pi * t);
        final env = (swell + shimmer).clamp(0.12, 1.0);
        final alpha = 0.08 + 0.28 * env;
        surfLp = (1.0 - alpha) * surfLp + alpha * white;
        deepLp = 0.94 * deepLp + 0.06 * white;
        raw[i] = (surfLp * 0.48 * env + deepLp * 0.25) * 0.85 * gain;
      }
    }

    // Circular cosine crossfade at seam
    final out = Float64List(totalSamples);
    for (int i = 0; i < totalSamples; i++) {
      out[i] = raw[i];
    }
    for (int i = 0; i < fadeSamples; i++) {
      final alpha = i / fadeSamples;
      final w = 0.5 - 0.5 * math.cos(math.pi * alpha);
      out[i] = (1.0 - w) * raw[totalSamples + i] + w * raw[i];
    }

    return _encodePcm16MonoWav(out, sampleRate);
  }

  /// Scales 16-bit PCM sample amplitudes of a standard 44-byte header WAV buffer.
  static Uint8List scaleWavVolume(Uint8List wavBytes, double volume) {
    if (wavBytes.length <= 44) return wavBytes;
    final gain = volume.clamp(0.0, 1.0);
    if ((gain - 1.0).abs() < 0.005) return wavBytes;

    final copy = Uint8List.fromList(wavBytes);
    final bd = ByteData.sublistView(copy);
    for (int offset = 44; offset + 1 < copy.length; offset += 2) {
      final sample = bd.getInt16(offset, Endian.little);
      final scaled = (sample * gain).round().clamp(-32767, 32767);
      bd.setInt16(offset, scaled, Endian.little);
    }
    return copy;
  }

  static Uint8List _encodePcm16MonoWav(Float64List samples, int sampleRate) {
    final dataByteLength = samples.length * 2;
    final totalLength = 44 + dataByteLength;
    final bytes = Uint8List(totalLength);
    final bd = ByteData.sublistView(bytes);

    // RIFF header
    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    bd.setUint32(4, 36 + dataByteLength, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);

    // fmt subchunk
    bytes.setRange(12, 16, 'fmt '.codeUnits);
    bd.setUint32(16, 16, Endian.little); // PCM chunk size
    bd.setUint16(20, 1, Endian.little); // AudioFormat = 1 (PCM)
    bd.setUint16(22, 1, Endian.little); // NumChannels = 1 (Mono)
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    bd.setUint16(32, 2, Endian.little); // BlockAlign
    bd.setUint16(34, 16, Endian.little); // BitsPerSample

    // data subchunk
    bytes.setRange(36, 40, 'data'.codeUnits);
    bd.setUint32(40, dataByteLength, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      final pcmVal = (samples[i] * 32767.0).round().clamp(-32767, 32767);
      bd.setInt16(44 + i * 2, pcmVal, Endian.little);
    }

    return bytes;
  }
}

/// Offline looping ambient soundscape player integrated with Pomodoro Focus Timer.
class AmbientSoundService extends ChangeNotifier {
  static final AmbientSoundService _instance = AmbientSoundService._internal();
  factory AmbientSoundService() => _instance;
  static AmbientSoundService get instance => _instance;

  AmbientSoundService._internal();

  AudioPlayer? _audioPlayer;
  AudioPlayer get audioPlayer => _audioPlayer ??= AudioPlayer();

  AmbientSoundType _selectedTrack = AmbientSoundType.off;
  double _volume = 0.65;
  bool _isPlaying = false;
  int _loopSessionToken = 0;

  /// When true, skips native AudioPlayer / OS process calls for deterministic unit/widget tests.
  bool testMode = false;

  Process? _linuxProcess;
  Directory? _tempAudioDir;
  final Map<AmbientSoundType, Uint8List> _rawWavCache = {};

  AmbientSoundType get selectedTrack => _selectedTrack;
  double get volume => _volume;
  bool get isPlaying => _isPlaying && _selectedTrack != AmbientSoundType.off;

  /// Loads persisted ambient track and volume preferences from [StorageService].
  void loadPreferences(StorageService storage) {
    _selectedTrack = AmbientSoundType.fromId(storage.getAmbientSoundTrack());
    _volume = storage.getAmbientSoundVolume();
    notifyListeners();
  }

  /// Selects an ambient soundscape track, persists the choice, and optionally starts playback.
  Future<void> selectTrack(
    AmbientSoundType track, {
    StorageService? storage,
    bool autoPlay = true,
  }) async {
    final trackChanged = _selectedTrack != track;
    _selectedTrack = track;
    if (storage != null) {
      await storage.setAmbientSoundTrack(track.id);
    }

    if (track == AmbientSoundType.off) {
      await stop();
      return;
    }

    if (autoPlay || _isPlaying) {
      if (trackChanged || !_isPlaying) {
        await play();
      } else {
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Updates the ambient volume (0.0 to 1.0) and persists it to [StorageService].
  Future<void> setVolume(
    double newVolume, {
    StorageService? storage,
  }) async {
    final clamped = newVolume.clamp(0.0, 1.0);
    if ((_volume - clamped).abs() < 0.005) return;
    _volume = clamped;
    if (storage != null) {
      await storage.setAmbientSoundVolume(_volume);
    }
    notifyListeners();

    if (!_isPlaying || _selectedTrack == AmbientSoundType.off || testMode) {
      return;
    }

    if (!kIsWeb && Platform.isLinux) {
      // Refresh volume-scaled file for Linux native loop
      await _writeLinuxScaledWav(_selectedTrack);
    } else {
      try {
        await audioPlayer.setVolume(_volume);
      } catch (_) {}
    }
  }

  /// Toggles ambient sound playback on or off for the currently selected track.
  Future<void> togglePlay() async {
    if (_selectedTrack == AmbientSoundType.off) return;
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Automatically starts ambient playback when a Pomodoro Focus session begins.
  Future<void> onFocusTimerStarted() async {
    if (_selectedTrack == AmbientSoundType.off) return;
    if (!_isPlaying) {
      await play();
    }
  }

  /// Automatically pauses ambient playback when a Focus session pauses, resets, or finishes.
  Future<void> onFocusTimerStopped() async {
    if (_isPlaying) {
      await pause();
    }
  }

  /// Starts infinite looping playback of the selected ambient track.
  Future<void> play() async {
    if (_selectedTrack == AmbientSoundType.off) return;
    final token = ++_loopSessionToken;
    _killLinuxProcess();
    _isPlaying = true;
    notifyListeners();

    if (testMode) return;

    final track = _selectedTrack;
    if (!kIsWeb && Platform.isLinux) {
      unawaited(_runLinuxLoop(track, token));
      return;
    }

    try {
      await audioPlayer.stop();
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.setVolume(_volume);
      final assetPath = track.assetPath;
      if (assetPath != null) {
        await audioPlayer.play(AssetSource(assetPath));
      } else {
        final bytes = await _getRawWavBytes(track);
        await audioPlayer.play(BytesSource(bytes));
      }
    } catch (e) {
      debugPrint('AmbientSoundService play error: $e');
    }
  }

  /// Pauses current ambient playback while preserving the selected track.
  Future<void> pause() async {
    _loopSessionToken++;
    _isPlaying = false;
    _killLinuxProcess();
    notifyListeners();

    if (testMode) return;
    if (!kIsWeb && !Platform.isLinux) {
      try {
        await audioPlayer.pause();
      } catch (_) {}
    }
  }

  /// Stops current ambient playback completely.
  Future<void> stop() async {
    _loopSessionToken++;
    _isPlaying = false;
    _killLinuxProcess();
    notifyListeners();

    if (testMode) return;
    if (!kIsWeb && !Platform.isLinux) {
      try {
        await audioPlayer.stop();
      } catch (_) {}
    }
  }

  Future<Uint8List> _getRawWavBytes(AmbientSoundType track) async {
    final cached = _rawWavCache[track];
    if (cached != null) return cached;

    final assetPath = track.assetPath;
    if (assetPath != null) {
      try {
        final byteData = await rootBundle.load('assets/$assetPath');
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        _rawWavCache[track] = bytes;
        return bytes;
      } catch (_) {}
    }

    final generated = AmbientSoundGenerator.generateWavBytes(
      track,
      durationSeconds: 4,
    );
    _rawWavCache[track] = generated;
    return generated;
  }

  Future<File> _writeLinuxScaledWav(AmbientSoundType track) async {
    final rawBytes = await _getRawWavBytes(track);
    final scaledBytes = AmbientSoundGenerator.scaleWavVolume(rawBytes, _volume);
    _tempAudioDir ??= await Directory.systemTemp.createTemp('taskapp_ambient_');
    final file = File('${_tempAudioDir!.path}/ambient_${track.id}.wav');
    await file.writeAsBytes(scaledBytes, flush: true);
    return file;
  }

  Future<void> _runLinuxLoop(AmbientSoundType track, int token) async {
    try {
      final file = await _writeLinuxScaledWav(track);
      String? workingCmd;
      const candidates = ['pw-play', 'paplay', 'aplay'];

      while (_isPlaying && _loopSessionToken == token && _selectedTrack == track) {
        bool playedOnce = false;
        final cmdsToTry = workingCmd != null ? [workingCmd] : candidates;

        for (final cmd in cmdsToTry) {
          if (!_isPlaying || _loopSessionToken != token) return;
          try {
            final proc = await Process.start(cmd, [file.path]);
            _linuxProcess = proc;
            final exitCode = await proc.exitCode;
            if (_loopSessionToken != token || !_isPlaying) return;
            if (exitCode == 0) {
              workingCmd = cmd;
              playedOnce = true;
              break;
            }
          } catch (_) {
            continue;
          }
        }

        if (!playedOnce) {
          // No working CLI audio player found on this Linux machine
          break;
        }
      }
    } catch (e) {
      debugPrint('AmbientSoundService Linux loop error: $e');
    }
  }

  void _killLinuxProcess() {
    try {
      _linuxProcess?.kill(ProcessSignal.sigterm);
    } catch (_) {}
    _linuxProcess = null;
  }
}
