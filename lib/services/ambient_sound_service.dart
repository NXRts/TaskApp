import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show AppExitResponse;
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
    subtitle: 'Gentle Rain • Rekaman rintik hujan alami penenang fokus',
    icon: Icons.water_drop_outlined,
    assetPath: 'sounds/ambient_gentle_rain.wav',
  ),
  quietStudy(
    id: 'quiet_study',
    label: 'Suasana Kafe',
    subtitle: 'Quiet Study • Rekaman suasana kafe & ruang baca',
    icon: Icons.local_cafe_outlined,
    assetPath: 'sounds/ambient_quiet_study.wav',
  ),
  whiteNoise(
    id: 'white_noise',
    label: 'Ombak Malam',
    subtitle: 'Night Waves • Rekaman debur ombak pantai alami',
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
/// offline ambient soundscapes.
class AmbientSoundGenerator {
  static const int defaultSampleRate = 22050;

  static double _smoothNoteEnv(
    double dt,
    double dur, {
    double attack = 0.035,
    double decayRate = 2.2,
  }) {
    if (dt < 0.0 || dt >= dur) return 0.0;
    final att = 0.5 - 0.5 * math.cos(math.pi * math.min(1.0, dt / attack));
    double rel = 1.0;
    if (dt > dur - 0.12) {
      rel = 0.5 + 0.5 * math.cos(math.pi * ((dt - (dur - 0.12)) / 0.12));
    }
    return att * math.exp(-dt * decayRate) * rel;
  }

  /// Generates a valid 16-bit mono RIFF/WAVE byte buffer with a seamless loop seam.
  static Uint8List generateWavBytes(
    AmbientSoundType type, {
    int sampleRate = defaultSampleRate,
    int durationSeconds = 4,
    double volumeScale = 1.0,
  }) {
    final totalSamples = math.max(sampleRate, sampleRate * durationSeconds);
    final fadeSamples = math.min(totalSamples ~/ 4, (sampleRate * 0.4).round());
    final rawLength = totalSamples + fadeSamples;
    final raw = Float64List(rawLength);
    final gain = volumeScale.clamp(0.0, 1.0);
    final durSec = totalSamples / sampleRate;

    if (type == AmbientSoundType.gentleRain) {
      const dropletNotes = [523.25, 392.00, 659.25, 587.33, 440.00, 329.63, 493.88, 392.00];
      const padFreqs = [130.81, 196.00, 246.94, 293.66];
      for (int i = 0; i < rawLength; i++) {
        final tSec = i / sampleRate;
        final tMod = (i % totalSamples) / sampleRate;

        double pad = 0.0;
        for (int n = 0; n < padFreqs.length; n++) {
          final amp = n == 0 ? 0.14 : 0.09;
          pad += amp * math.sin(2.0 * math.pi * padFreqs[n] * tSec);
        }

        double drop = 0.0;
        final stepIdx = (tMod / 0.5).floor();
        for (int k = math.max(0, stepIdx - 2); k <= stepIdx; k++) {
          final freq = dropletNotes[k % dropletNotes.length];
          final dt = tMod - k * 0.5;
          final env = _smoothNoteEnv(dt, 1.2, attack: 0.025, decayRate: 2.5);
          if (env > 0.0) {
            drop += env * 0.18 * math.sin(2.0 * math.pi * freq * dt);
          }
        }
        raw[i] = (pad + drop) * gain;
      }
    } else if (type == AmbientSoundType.quietStudy) {
      const chordFreqs = [174.61, 220.00, 261.63, 329.63];
      const melodyFreqs = [440.00, 523.25, 659.25, 587.33];
      for (int i = 0; i < rawLength; i++) {
        final tSec = i / sampleRate;
        final tMod = (i % totalSamples) / sampleRate;

        double pad = 0.0;
        for (final f in chordFreqs) {
          pad += 0.09 *
              (math.sin(2.0 * math.pi * f * tSec) +
                  0.08 * math.sin(4.0 * math.pi * f * tSec));
        }

        final beatIdx = tMod.floor();
        final dtM = tMod - beatIdx;
        final melFreq = melodyFreqs[beatIdx % melodyFreqs.length];
        final envM = _smoothNoteEnv(dtM, 0.95, attack: 0.04, decayRate: 2.0);
        final mel = envM * 0.16 * math.sin(2.0 * math.pi * melFreq * dtM);

        raw[i] = (pad + mel) * gain;
      }
    } else if (type == AmbientSoundType.whiteNoise) {
      const droneFreqs = [73.42, 110.00, 146.83, 185.00, 220.00, 293.66];
      for (int i = 0; i < rawLength; i++) {
        final tSec = i / sampleRate;
        final tNorm = (i % totalSamples) / totalSamples;
        final tMod = (i % totalSamples) / sampleRate;

        final breath = 0.55 - 0.38 * math.cos(2.0 * math.pi * tNorm);
        double drone = 0.0;
        for (int n = 0; n < droneFreqs.length; n++) {
          final amp = n < 2 ? 0.12 : 0.07;
          drone += amp * math.sin(2.0 * math.pi * droneFreqs[n] * tSec);
        }

        final bowlEnv = _smoothNoteEnv(
          tMod % math.max(1.0, durSec * 0.5),
          math.max(1.0, durSec * 0.5),
          attack: 0.06,
          decayRate: 1.2,
        );
        final bowl = bowlEnv *
            0.14 *
            (0.65 * math.sin(2.0 * math.pi * 293.66 * tSec) +
                0.35 * math.sin(2.0 * math.pi * 440.00 * tSec));

        raw[i] = (drone * breath + bowl) * gain;
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
///
/// On Linux desktop, streams raw 16-bit PCM slices over `stdin` to `pacat` / `aplay`:
/// - Adjusting volume scales samples in real time at the current [_pcmReadCursor]
///   without restarting the track from 0:00.
/// - Closing the application automatically closes the `stdin` pipe (`EOF`),
///   causing the audio process to exit immediately so it never plays in the background.
class AmbientSoundService extends ChangeNotifier {
  static final AmbientSoundService _instance = AmbientSoundService._internal();
  factory AmbientSoundService() => _instance;
  static AmbientSoundService get instance => _instance;

  AmbientSoundService._internal();

  AudioPlayer? _audioPlayer;
  AudioPlayer get audioPlayer => _audioPlayer ??= AudioPlayer();

  AmbientSoundType _selectedTrack = AmbientSoundType.off;
  double _volume = 0.65;
  double _currentGain = 0.65;
  bool _isPlaying = false;
  int _loopSessionToken = 0;

  /// Current sample read position within the active track's PCM buffer.
  int _pcmReadCursor = 0;
  AmbientSoundType _cursorTrack = AmbientSoundType.off;

  /// When true, skips native AudioPlayer / OS process calls for deterministic unit/widget tests.
  bool testMode = false;

  Process? _linuxProcess;
  Timer? _linuxFeedTimer;
  AppLifecycleListener? _lifecycleListener;
  bool _cleanedOrphansOnStartup = false;
  final Map<AmbientSoundType, Uint8List> _rawWavCache = {};

  AmbientSoundType get selectedTrack => _selectedTrack;
  double get volume => _volume;
  bool get isPlaying => _isPlaying && _selectedTrack != AmbientSoundType.off;

  @visibleForTesting
  int get pcmReadCursor => _pcmReadCursor;

  void _ensureLifecycleListener() {
    if (testMode || _lifecycleListener != null) return;
    try {
      _lifecycleListener = AppLifecycleListener(
        onDetach: () {
          stop();
        },
        onExitRequested: () async {
          await stop();
          return AppExitResponse.exit;
        },
      );
    } catch (_) {}
  }

  /// Loads persisted ambient track and volume preferences from [StorageService].
  void loadPreferences(StorageService storage) {
    _ensureLifecycleListener();
    if (!_cleanedOrphansOnStartup && !testMode && !kIsWeb && Platform.isLinux) {
      _cleanedOrphansOnStartup = true;
      unawaited(_cleanupOrphanedLinuxPlayers());
    }
    _selectedTrack = AmbientSoundType.fromId(storage.getAmbientSoundTrack());
    _volume = storage.getAmbientSoundVolume();
    _currentGain = _volume;
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
    if (trackChanged) {
      _pcmReadCursor = 0;
      _cursorTrack = track;
    }
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

  /// Updates the ambient volume (0.0 to 1.0) in real time without restarting the track.
  Future<void> setVolume(
    double newVolume, {
    StorageService? storage,
  }) async {
    final clamped = newVolume.clamp(0.0, 1.0);
    if ((_volume - clamped).abs() < 0.002) return;
    _volume = clamped;
    if (storage != null) {
      await storage.setAmbientSoundVolume(_volume);
    }
    notifyListeners();

    if (!_isPlaying || _selectedTrack == AmbientSoundType.off || testMode) {
      _currentGain = _volume;
      return;
    }

    // On Linux, the active stdin PCM feeder automatically interpolates _currentGain
    // toward _volume on the next 40ms chunk at the exact current _pcmReadCursor.
    if (!kIsWeb && !Platform.isLinux) {
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

  /// Starts infinite looping playback of the selected ambient track from current cursor.
  Future<void> play() async {
    if (_selectedTrack == AmbientSoundType.off) return;
    _ensureLifecycleListener();
    final token = ++_loopSessionToken;
    _stopLinuxStreamProcess();

    if (_cursorTrack != _selectedTrack) {
      _pcmReadCursor = 0;
      _cursorTrack = _selectedTrack;
    }
    _currentGain = _volume;
    _isPlaying = true;
    notifyListeners();

    if (testMode) {
      // Advance simulated cursor slightly in test mode so tests can verify cursor continuity
      _pcmReadCursor += 100;
      return;
    }

    final track = _selectedTrack;
    if (!kIsWeb && Platform.isLinux) {
      unawaited(_startLinuxStdinStream(track, token));
      return;
    }

    try {
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

  /// Pauses current ambient playback while preserving [_pcmReadCursor].
  Future<void> pause() async {
    _loopSessionToken++;
    _isPlaying = false;
    _stopLinuxStreamProcess();
    notifyListeners();

    if (testMode) return;
    if (!kIsWeb && Platform.isLinux) {
      unawaited(_cleanupOrphanedLinuxPlayers());
    } else if (!kIsWeb) {
      try {
        await audioPlayer.pause();
      } catch (_) {}
    }
  }

  /// Stops current ambient playback completely and resets [_pcmReadCursor].
  Future<void> stop() async {
    _loopSessionToken++;
    _isPlaying = false;
    _pcmReadCursor = 0;
    _stopLinuxStreamProcess();
    notifyListeners();

    if (testMode) return;
    if (!kIsWeb && Platform.isLinux) {
      unawaited(_cleanupOrphanedLinuxPlayers());
    } else if (!kIsWeb) {
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

  /// Streams 16-bit PCM slices continuously over `stdin` to `pacat` or `aplay`.
  /// Because audio is piped via `stdin`, closing the app closes the pipe (`EOF`)
  /// and terminates the player automatically, while volume changes scale samples
  /// in-place at [_pcmReadCursor] without restarting from 0:00.
  Future<void> _startLinuxStdinStream(AmbientSoundType track, int token) async {
    try {
      await _cleanupOrphanedLinuxPlayers();
      final wavBytes = await _getRawWavBytes(track);
      if (!_isPlaying || _loopSessionToken != token || wavBytes.length <= 44) {
        return;
      }

      final headerBd = ByteData.sublistView(wavBytes);
      final sampleRate = headerBd.getUint32(24, Endian.little);
      final totalSamples = (wavBytes.length - 44) ~/ 2;
      if (totalSamples <= 0) return;

      _pcmReadCursor = _pcmReadCursor % totalSamples;

      Process? proc;
      try {
        proc = await Process.start('pacat', [
          '--playback',
          '--format=s16le',
          '--rate=$sampleRate',
          '--channels=1',
          '--latency-msec=80',
          '--client-name=TaskAppAmbientZen',
        ]);
      } catch (_) {
        try {
          proc = await Process.start('aplay', [
            '-q',
            '-t',
            'raw',
            '-f',
            'S16_LE',
            '-r',
            '$sampleRate',
            '-c',
            '1',
            '-',
          ]);
        } catch (_) {}
      }

      if (proc == null) return;
      if (!_isPlaying || _loopSessionToken != token) {
        try {
          proc.kill(ProcessSignal.sigterm);
        } catch (_) {}
        return;
      }

      _linuxProcess = proc;
      // Ignore broken pipe errors when process is killed on pause/stop
      proc.stdin.done.ignore();

      final sw = Stopwatch()..start();
      int samplesSent = 0;
      final int prebufferSamples = (sampleRate * 0.14).round(); // 140ms lookahead
      final int maxChunkSamples = (sampleRate * 0.25).round();

      void feedSlices() {
        if (!_isPlaying || _loopSessionToken != token || _linuxProcess != proc) {
          return;
        }
        final elapsedSamples = (sw.elapsedMicroseconds * sampleRate) ~/ 1000000;
        final targetSamples = elapsedSamples + prebufferSamples;
        int count = targetSamples - samplesSent;
        if (count <= 0) return;
        if (count > maxChunkSamples) {
          // Recover gracefully if event loop paused briefly
          samplesSent = targetSamples - prebufferSamples;
          count = prebufferSamples;
        }

        final outBytes = Uint8List(count * 2);
        final outBd = ByteData.sublistView(outBytes);
        final targetVol = _volume;

        for (int i = 0; i < count; i++) {
          _currentGain += 0.003 * (targetVol - _currentGain);
          final sample = headerBd.getInt16(44 + _pcmReadCursor * 2, Endian.little);
          _pcmReadCursor++;
          if (_pcmReadCursor >= totalSamples) {
            _pcmReadCursor = 0;
          }
          final scaled = (sample * _currentGain).round().clamp(-32767, 32767);
          outBd.setInt16(i * 2, scaled, Endian.little);
        }

        try {
          proc!.stdin.add(outBytes);
          samplesSent += count;
        } catch (_) {}
      }

      feedSlices();
      _linuxFeedTimer = Timer.periodic(
        const Duration(milliseconds: 35),
        (_) => feedSlices(),
      );
    } catch (e) {
      debugPrint('AmbientSoundService Linux stdin stream error: $e');
    }
  }

  void _stopLinuxStreamProcess() {
    _linuxFeedTimer?.cancel();
    _linuxFeedTimer = null;
    final proc = _linuxProcess;
    _linuxProcess = null;
    if (proc != null) {
      try {
        proc.stdin.close().ignore();
      } catch (_) {}
      try {
        proc.kill(ProcessSignal.sigterm);
      } catch (_) {}
    }
  }

  /// Cleans up any orphaned background audio processes from previous app runs.
  Future<void> _cleanupOrphanedLinuxPlayers() async {
    if (kIsWeb || !Platform.isLinux || testMode) return;
    for (final pattern in [
      'TaskAppAmbientZen',
      'taskapp_zen_',
      'taskapp_ambient_',
      'ambient_v2_',
      'ambient_v3_',
    ]) {
      try {
        await Process.run('pkill', ['-f', pattern]);
      } catch (_) {}
    }
  }
}
