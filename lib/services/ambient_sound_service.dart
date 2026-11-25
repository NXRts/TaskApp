import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show AppExitResponse;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

/// All 9 Ambient Sound tracks from FocEase (https://focease.vercel.app/),
/// capable of playing simultaneously as a multi-track audio mixer.
enum AmbientSoundTrack {
  rain(
    id: 'rain',
    name: 'Rain',
    subtitle: 'Hujan rintik alami',
    assetPath: 'sounds/ambient_rain.wav',
    icon: Icons.water_drop_outlined,
    sliderColor: Color(0xFF3B82F6),
    activeBgColor: Color(0xFF2563EB),
    activeTextColor: Color(0xFF60A5FA),
  ),
  fire(
    id: 'fire',
    name: 'Fireplace',
    subtitle: 'Perapian kayu hangat',
    assetPath: 'sounds/ambient_fire.wav',
    icon: Icons.local_fire_department_outlined,
    sliderColor: Color(0xFFF97316),
    activeBgColor: Color(0xFFEA580C),
    activeTextColor: Color(0xFFFB923C),
  ),
  stream(
    id: 'stream',
    name: 'River',
    subtitle: 'Aliran sungai tenang',
    assetPath: 'sounds/ambient_stream.wav',
    icon: Icons.waves_rounded,
    sliderColor: Color(0xFF06B6D4),
    activeBgColor: Color(0xFF0891B2),
    activeTextColor: Color(0xFF22D3EE),
  ),
  wind(
    id: 'wind',
    name: 'Wind',
    subtitle: 'Desir angin pepohonan',
    assetPath: 'sounds/ambient_wind.wav',
    icon: Icons.air_rounded,
    sliderColor: Color(0xFF14B8A6),
    activeBgColor: Color(0xFF0D9488),
    activeTextColor: Color(0xFF2DD4BF),
  ),
  cafe(
    id: 'cafe',
    name: 'Cafe Ambience',
    subtitle: 'Suasana kedai kopi & ruang baca',
    assetPath: 'sounds/ambient_cafe.wav',
    icon: Icons.local_cafe_outlined,
    sliderColor: Color(0xFFF59E0B),
    activeBgColor: Color(0xFFD97706),
    activeTextColor: Color(0xFFFBBF24),
  ),
  birds(
    id: 'birds',
    name: 'Morning Birds',
    subtitle: 'Kicau burung pagi hari',
    assetPath: 'sounds/ambient_birds.wav',
    icon: Icons.flutter_dash_outlined,
    sliderColor: Color(0xFF22C55E),
    activeBgColor: Color(0xFF16A34A),
    activeTextColor: Color(0xFF4ADE80),
  ),
  thunder(
    id: 'thunder',
    name: 'Thunderstorm',
    subtitle: 'Gemuruh petir kejauhan',
    assetPath: 'sounds/ambient_thunder.wav',
    icon: Icons.thunderstorm_outlined,
    sliderColor: Color(0xFFEAB308),
    activeBgColor: Color(0xFFCA8A04),
    activeTextColor: Color(0xFFFACC15),
  ),
  night(
    id: 'night',
    name: 'Nature Night',
    subtitle: 'Suasana malam alam tenang',
    assetPath: 'sounds/ambient_night.wav',
    icon: Icons.nightlight_outlined,
    sliderColor: Color(0xFF6366F1),
    activeBgColor: Color(0xFF4F46E5),
    activeTextColor: Color(0xFF818CF8),
  ),
  ocean(
    id: 'ocean',
    name: 'Ocean Waves',
    subtitle: 'Deburan ombak pantai',
    assetPath: 'sounds/ambient_ocean.wav',
    icon: Icons.water_outlined,
    sliderColor: Color(0xFF0EA5E9),
    activeBgColor: Color(0xFF0284C7),
    activeTextColor: Color(0xFF38BDF8),
  );

  final String id;
  final String name;
  final String subtitle;
  final String assetPath;
  final IconData icon;
  final Color sliderColor;
  final Color activeBgColor;
  final Color activeTextColor;

  const AmbientSoundTrack({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.assetPath,
    required this.icon,
    required this.sliderColor,
    required this.activeBgColor,
    required this.activeTextColor,
  });

  static AmbientSoundTrack? fromId(String? id) {
    for (final value in AmbientSoundTrack.values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// Sleep timer presets matching FocEase (No Timer, 15m, 30m, 45m, 1h).
class AmbientTimerOption {
  final String label;
  final int seconds;

  const AmbientTimerOption({required this.label, required this.seconds});

  static const List<AmbientTimerOption> options = [
    AmbientTimerOption(label: 'No Timer', seconds: 0),
    AmbientTimerOption(label: '15 Minutes', seconds: 900),
    AmbientTimerOption(label: '30 Minutes', seconds: 1800),
    AmbientTimerOption(label: '45 Minutes', seconds: 2700),
    AmbientTimerOption(label: '1 Hour', seconds: 3600),
  ];
}

/// Pure-Dart procedural 16-bit PCM WAV synthesizer and volume scaler fallback.
class AmbientSoundGenerator {
  static const int defaultSampleRate = 16000;

  /// Generates a valid 16-bit mono RIFF/WAVE byte buffer with a seamless loop seam.
  static Uint8List generateWavBytes(
    AmbientSoundTrack track, {
    int sampleRate = defaultSampleRate,
    int durationSeconds = 2,
    double volumeScale = 1.0,
  }) {
    final totalSamples = math.max(sampleRate, sampleRate * durationSeconds);
    final fadeSamples = math.min(totalSamples ~/ 4, (sampleRate * 0.3).round());
    final rawLength = totalSamples + fadeSamples;
    final raw = Float64List(rawLength);
    final rng = math.Random(track.index * 97 + 13);
    final gain = volumeScale.clamp(0.0, 1.0);

    double lp1 = 0.0;
    double lp2 = 0.0;
    double lp3 = 0.0;
    final alpha = 0.06 + (track.index % 4) * 0.03;

    for (int i = 0; i < rawLength; i++) {
      final w = rng.nextDouble() * 2.0 - 1.0;
      lp1 += alpha * (w - lp1);
      lp2 += alpha * (lp1 - lp2);
      lp3 += alpha * (lp2 - lp3);
      final t = (i % totalSamples) / totalSamples;
      final mod = 0.85 + 0.15 * math.sin(2.0 * math.pi * t);
      raw[i] = lp3 * 0.45 * mod * gain;
    }

    final out = Float64List(totalSamples);
    for (int i = 0; i < totalSamples; i++) {
      out[i] = raw[i];
    }
    for (int i = 0; i < fadeSamples; i++) {
      final a = i / fadeSamples;
      final w = 0.5 - 0.5 * math.cos(math.pi * a);
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

    bytes.setRange(0, 4, 'RIFF'.codeUnits);
    bd.setUint32(4, 36 + dataByteLength, Endian.little);
    bytes.setRange(8, 12, 'WAVE'.codeUnits);

    bytes.setRange(12, 16, 'fmt '.codeUnits);
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);

    bytes.setRange(36, 40, 'data'.codeUnits);
    bd.setUint32(40, dataByteLength, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      final pcmVal = (samples[i] * 32767.0).round().clamp(-32767, 32767);
      bd.setInt16(44 + i * 2, pcmVal, Endian.little);
    }

    return bytes;
  }
}

/// Multi-track simultaneous offline Ambient Sounds mixer (modeled on FocEase).
///
/// - Any combination of the 9 [AmbientSoundTrack]s can play simultaneously.
/// - Each track has its own play/pause state, volume (`0.0..1.0`, default `0.5`),
///   and sample read cursor (`_trackCursors[track]`) so adjusting volume never
///   restarts a track from 0:00.
/// - Includes a Master Volume slider (`0.0..1.0`, default `1.0`), Sleep Timer
///   (`No Timer`, `15m`, `30m`, `45m`, `1h`), `Play All`, `Pause All`, and `Reset`.
/// - On Linux desktop, mixes all active tracks in real time into a single `stdin`
///   PCM stream to `pacat` / `aplay`, which automatically exits on `EOF` when
///   the app window closes.
class AmbientSoundService extends ChangeNotifier {
  static final AmbientSoundService _instance = AmbientSoundService._internal();
  factory AmbientSoundService() => _instance;
  static AmbientSoundService get instance => _instance;

  AmbientSoundService._internal() {
    for (final track in AmbientSoundTrack.values) {
      _playing[track] = false;
      _volumes[track] = defaultTrackVolume;
      _currentGains[track] = defaultTrackVolume;
      _trackCursors[track] = 0;
    }
  }

  static const double defaultTrackVolume = 0.5;
  static const double defaultMasterVolume = 1.0;
  static const MethodChannel _androidPcmChannel =
      MethodChannel('com.taskapp.taskapp/ambient_pcm');

  static final AudioContext _multiTrackAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  final Map<AmbientSoundTrack, bool> _playing = {};
  final Map<AmbientSoundTrack, double> _volumes = {};
  final Map<AmbientSoundTrack, double> _currentGains = {};
  final Map<AmbientSoundTrack, int> _trackCursors = {};
  final Map<AmbientSoundTrack, Uint8List> _rawWavCache = {};
  final Map<AmbientSoundTrack, AudioPlayer> _players = {};

  double _masterVolume = defaultMasterVolume;
  int _timerDuration = 0;
  int _timeLeft = 0;
  Timer? _sleepTimer;

  int _streamToken = 0;
  Process? _linuxProcess;
  Timer? _linuxFeedTimer;
  bool _useAndroidPlayerFallback = false;
  AppLifecycleListener? _lifecycleListener;
  bool _cleanedOrphansOnStartup = false;

  /// When true, skips native AudioPlayer / OS process calls for deterministic unit/widget tests.
  bool testMode = false;

  double get masterVolume => _masterVolume;
  int get timerDuration => _timerDuration;
  int get timeLeft => _timeLeft;

  bool isTrackPlaying(AmbientSoundTrack track) => _playing[track] ?? false;
  double getTrackVolume(AmbientSoundTrack track) =>
      _volumes[track] ?? defaultTrackVolume;

  int get activePlayingCount =>
      _playing.values.where((playing) => playing).length;

  bool get isAnyPlaying => activePlayingCount > 0;

  List<AmbientSoundTrack> get activeTracks => AmbientSoundTrack.values
      .where((track) => _playing[track] == true)
      .toList();

  @visibleForTesting
  int getTrackCursor(AmbientSoundTrack track) => _trackCursors[track] ?? 0;

  void _ensureLifecycleListener() {
    if (testMode || _lifecycleListener != null) return;
    try {
      _lifecycleListener = AppLifecycleListener(
        onDetach: () {
          stopAll();
        },
        onExitRequested: () async {
          await stopAll();
          return AppExitResponse.exit;
        },
      );
    } catch (_) {}
  }

  /// Loads persisted master volume, timer duration, and per-track volumes from [StorageService].
  void loadPreferences(StorageService storage) {
    _ensureLifecycleListener();
    if (!_cleanedOrphansOnStartup && !testMode && !kIsWeb && Platform.isLinux) {
      _cleanedOrphansOnStartup = true;
      unawaited(_cleanupOrphanedLinuxPlayers());
    }

    _masterVolume = storage.getAmbientMasterVolume();
    _timerDuration = storage.getAmbientTimerDuration();
    final savedVolumes = storage.getAmbientTrackVolumes();
    for (final track in AmbientSoundTrack.values) {
      final vol = savedVolumes[track.id] ?? defaultTrackVolume;
      _volumes[track] = vol;
      _currentGains[track] = vol * _masterVolume;
    }
    notifyListeners();
  }

  /// Toggles play/pause for a single [track] without interrupting other active tracks.
  Future<void> toggleSound(
    AmbientSoundTrack track, {
    StorageService? storage,
  }) async {
    _ensureLifecycleListener();
    final nowPlaying = !(_playing[track] ?? false);
    _playing[track] = nowPlaying;
    _currentGains[track] = getTrackVolume(track) * _masterVolume;

    if (nowPlaying && testMode) {
      _trackCursors[track] = (_trackCursors[track] ?? 0) + 120;
    }

    notifyListeners();
    await _syncPlaybackEngine(changedTrack: track);
  }

  /// Updates the volume (`0.0..1.0`) of a single [track] in real time without restarting it.
  Future<void> setSoundVolume(
    AmbientSoundTrack track,
    double volume, {
    StorageService? storage,
  }) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (((_volumes[track] ?? defaultTrackVolume) - clamped).abs() < 0.002) {
      return;
    }
    _volumes[track] = clamped;
    if (storage != null) {
      await _persistTrackVolumes(storage);
    }
    notifyListeners();

    if (testMode || !isTrackPlaying(track)) {
      _currentGains[track] = clamped * _masterVolume;
      return;
    }

    // On Linux and Android native PCM mixer, the mixer loop interpolates
    // _currentGains[track] toward _volumes[track] * _masterVolume at the
    // current cursor without restarting.
    if (!kIsWeb && Platform.isAndroid && !_useAndroidPlayerFallback) {
      unawaited(_syncAndroidNativeMixer());
      return;
    }
    if (!kIsWeb && !Platform.isLinux) {
      try {
        await _players[track]?.setVolume(clamped * _masterVolume);
      } catch (_) {}
    }
  }

  /// Updates the global master volume (`0.0..1.0`) across all active tracks in real time.
  Future<void> setMasterVolume(
    double volume, {
    StorageService? storage,
  }) async {
    final clamped = volume.clamp(0.0, 1.0);
    if ((_masterVolume - clamped).abs() < 0.002) return;
    _masterVolume = clamped;
    if (storage != null) {
      await storage.setAmbientMasterVolume(_masterVolume);
    }
    notifyListeners();

    if (testMode || !isAnyPlaying) return;

    if (!kIsWeb && Platform.isAndroid && !_useAndroidPlayerFallback) {
      unawaited(_syncAndroidNativeMixer());
      return;
    }
    if (!kIsWeb && !Platform.isLinux) {
      for (final track in activeTracks) {
        try {
          await _players[track]?.setVolume(getTrackVolume(track) * _masterVolume);
        } catch (_) {}
      }
    }
  }

  /// Plays all 9 ambient sound tracks simultaneously (FocEase "Play All").
  Future<void> playAll() async {
    _ensureLifecycleListener();
    for (final track in AmbientSoundTrack.values) {
      _playing[track] = true;
      _currentGains[track] = getTrackVolume(track) * _masterVolume;
      if (testMode) {
        _trackCursors[track] = (_trackCursors[track] ?? 0) + 120;
      }
    }
    notifyListeners();
    await _syncPlaybackEngine();
  }

  /// Pauses all currently playing ambient sound tracks (FocEase "Pause All").
  Future<void> stopAll() async {
    for (final track in AmbientSoundTrack.values) {
      _playing[track] = false;
    }
    _streamToken++;
    _stopLinuxStreamProcess();
    unawaited(_stopAndroidPcmStream());
    notifyListeners();

    if (testMode) return;

    if (!kIsWeb && Platform.isLinux) {
      unawaited(_cleanupOrphanedLinuxPlayers());
    } else if (!kIsWeb) {
      for (final player in _players.values) {
        try {
          await player.pause();
        } catch (_) {}
      }
    }
  }

  /// Stops all tracks and resets volumes to 50%, master to 100%, and timer to No Timer (FocEase "Reset").
  Future<void> resetAll({StorageService? storage}) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _timerDuration = 0;
    _timeLeft = 0;
    _masterVolume = defaultMasterVolume;

    for (final track in AmbientSoundTrack.values) {
      _playing[track] = false;
      _volumes[track] = defaultTrackVolume;
      _currentGains[track] = defaultTrackVolume;
      _trackCursors[track] = 0;
    }

    _streamToken++;
    _stopLinuxStreamProcess();
    unawaited(_stopAndroidPcmStream());

    if (storage != null) {
      await storage.setAmbientMasterVolume(defaultMasterVolume);
      await storage.setAmbientTimerDuration(0);
      await _persistTrackVolumes(storage);
    }

    notifyListeners();

    if (testMode) return;

    if (!kIsWeb && Platform.isLinux) {
      unawaited(_cleanupOrphanedLinuxPlayers());
    } else if (!kIsWeb) {
      for (final player in _players.values) {
        try {
          await player.stop();
        } catch (_) {}
      }
    }
  }

  /// Sets the sleep countdown timer duration in seconds (`0` = No Timer).
  Future<void> setTimerDuration(
    int seconds, {
    StorageService? storage,
  }) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _timerDuration = seconds < 0 ? 0 : seconds;
    _timeLeft = _timerDuration;

    if (storage != null) {
      await storage.setAmbientTimerDuration(_timerDuration);
    }

    if (_timerDuration > 0) {
      _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft <= 1) {
          timer.cancel();
          _sleepTimer = null;
          _timeLeft = 0;
          _timerDuration = 0;
          if (storage != null) {
            unawaited(storage.setAmbientTimerDuration(0));
          }
          unawaited(stopAll());
        } else {
          _timeLeft--;
          notifyListeners();
        }
      });
    }

    notifyListeners();
  }

  Future<void> _persistTrackVolumes(StorageService storage) async {
    final map = <String, double>{
      for (final track in AmbientSoundTrack.values)
        track.id: getTrackVolume(track),
    };
    await storage.setAmbientTrackVolumes(map);
  }

  Future<void> _syncPlaybackEngine({AmbientSoundTrack? changedTrack}) async {
    if (testMode) return;

    if (!isAnyPlaying) {
      _streamToken++;
      _stopLinuxStreamProcess();
      unawaited(_stopAndroidPcmStream());
      if (!kIsWeb && !Platform.isLinux) {
        for (final player in _players.values) {
          try {
            await player.pause();
          } catch (_) {}
        }
      }
      return;
    }

    if (!kIsWeb && Platform.isLinux) {
      // Preload WAV bytes for all active tracks
      for (final track in activeTracks) {
        await _getRawWavBytes(track);
      }
      // If the single Linux stdin mixer stream is not running yet, start it
      if (_linuxProcess == null || _linuxFeedTimer == null) {
        final token = ++_streamToken;
        unawaited(_startLinuxMultiTrackMixer(token));
      }
      return;
    }

    if (!kIsWeb && Platform.isAndroid && !_useAndroidPlayerFallback) {
      final ok = await _syncAndroidNativeMixer();
      if (ok) return;
      _useAndroidPlayerFallback = true;
    }

    if (!kIsWeb) {
      try {
        await AudioPlayer.global.setAudioContext(_multiTrackAudioContext);
      } catch (_) {}
      final tracksToUpdate =
          changedTrack != null ? [changedTrack] : AmbientSoundTrack.values;
      for (final track in tracksToUpdate) {
        final shouldPlay = isTrackPlaying(track);
        if (shouldPlay) {
          final player = _players.putIfAbsent(
            track,
            () => AudioPlayer(playerId: 'ambient_${track.id}'),
          );
          try {
            await player.setAudioContext(_multiTrackAudioContext);
            await player.setPlayerMode(PlayerMode.mediaPlayer);
            await player.setReleaseMode(ReleaseMode.loop);
            await player.setVolume(getTrackVolume(track) * _masterVolume);
            await player.play(AssetSource(track.assetPath));
          } catch (e) {
            debugPrint('AmbientSoundService play error (${track.id}): $e');
          }
        } else {
          try {
            await _players[track]?.pause();
          } catch (_) {}
        }
      }
    }
  }

  Future<Uint8List> _getRawWavBytes(AmbientSoundTrack track) async {
    final cached = _rawWavCache[track];
    if (cached != null) return cached;

    try {
      final byteData = await rootBundle.load('assets/${track.assetPath}');
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      _rawWavCache[track] = bytes;
      return bytes;
    } catch (_) {}

    final generated = AmbientSoundGenerator.generateWavBytes(
      track,
      durationSeconds: 3,
    );
    _rawWavCache[track] = generated;
    return generated;
  }

  /// Preloads WAV buffers into memory for all [AmbientSoundTrack]s.
  @visibleForTesting
  Future<void> preloadAllTracks() async {
    for (final track in AmbientSoundTrack.values) {
      await _getRawWavBytes(track);
    }
  }

  /// Mixes [sampleCount] 16-bit PCM mono samples across all currently active tracks,
  /// advancing each track's read cursor with a 2.5-second dual-head equal-power
  /// circular crossfade at the loop boundary so transitions are 100% seamless.
  @visibleForTesting
  Uint8List mixActivePcmSamples(int sampleCount) {
    final outBytes = Uint8List(sampleCount * 2);
    final outBd = ByteData.sublistView(outBytes);
    final playingTracks = activeTracks;
    const int crossfadeWindowSamples = 16000 * 5 ~/ 2; // 2.5s @ 16000Hz

    final activeViews = <({
      AmbientSoundTrack track,
      ByteData bd,
      int totalSamples,
      int fadeLen,
      int effectiveLoopLen,
      double targetGain,
    })>[];

    for (final track in playingTracks) {
      final wav = _rawWavCache[track];
      if (wav != null && wav.length > 44) {
        final total = (wav.length - 44) ~/ 2;
        if (total > 0) {
          final fadeLen = math.min(crossfadeWindowSamples, total ~/ 4);
          final effectiveLoopLen = math.max(1, total - fadeLen);
          activeViews.add((
            track: track,
            bd: ByteData.sublistView(wav),
            totalSamples: total,
            fadeLen: fadeLen,
            effectiveLoopLen: effectiveLoopLen,
            targetGain: getTrackVolume(track) * _masterVolume,
          ));
        }
      }
    }

    for (int i = 0; i < sampleCount; i++) {
      double mixed = 0.0;
      for (final item in activeViews) {
        final prevGain = _currentGains[item.track] ?? item.targetGain;
        final curGain = prevGain + 0.003 * (item.targetGain - prevGain);
        _currentGains[item.track] = curGain;

        int cursor = (_trackCursors[item.track] ?? 0) % item.effectiveLoopLen;
        double sampleVal;
        if (item.fadeLen > 0 && cursor >= item.effectiveLoopLen - item.fadeLen) {
          // Dual-head equal-power circular crossfade between loop tail and loop head
          final fadePos = cursor - (item.effectiveLoopLen - item.fadeLen);
          final phase = (fadePos / item.fadeLen) * (math.pi * 0.5);
          final tailWeight = math.cos(phase);
          final headWeight = math.sin(phase);
          final tailIdx = item.fadeLen + cursor;
          final tailSample =
              item.bd.getInt16(44 + tailIdx * 2, Endian.little).toDouble();
          final headSample =
              item.bd.getInt16(44 + fadePos * 2, Endian.little).toDouble();
          sampleVal = tailSample * tailWeight + headSample * headWeight;
        } else {
          final sampleIdx = item.fadeLen + cursor;
          sampleVal =
              item.bd.getInt16(44 + sampleIdx * 2, Endian.little).toDouble();
        }

        cursor++;
        if (cursor >= item.effectiveLoopLen) cursor = 0;
        _trackCursors[item.track] = cursor;

        mixed += sampleVal * curGain;
      }
      final clamped = mixed.round().clamp(-32767, 32767);
      outBd.setInt16(i * 2, clamped, Endian.little);
    }

    return outBytes;
  }

  /// Synchronizes play/pause states and volumes with the dedicated native Android
  /// `TaskAppAmbientMixerThread` (`AudioTrack.WRITE_BLOCKING` + 2.5s circular crossfade).
  Future<bool> _syncAndroidNativeMixer() async {
    try {
      final tracksPayload = AmbientSoundTrack.values
          .map(
            (t) => <String, dynamic>{
              'id': t.id,
              'assetPath': 'assets/${t.assetPath}',
              'playing': isTrackPlaying(t),
              'volume': getTrackVolume(t),
            },
          )
          .toList();
      await _androidPcmChannel.invokeMethod('syncState', {
        'tracks': tracksPayload,
        'masterVolume': _masterVolume,
      });
      return true;
    } catch (e) {
      debugPrint('AmbientSoundService Android native mixer sync error: $e');
      return false;
    }
  }

  Future<void> _stopAndroidPcmStream() async {
    if (!kIsWeb && Platform.isAndroid && !testMode) {
      try {
        await _androidPcmChannel.invokeMethod('stop');
      } catch (_) {}
    }
  }

  /// Mixes all currently active tracks in real time into a single `stdin` PCM stream.
  Future<void> _startLinuxMultiTrackMixer(int token) async {
    try {
      await _cleanupOrphanedLinuxPlayers();
      if (!isAnyPlaying || _streamToken != token) return;

      const int sampleRate = 16000;

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
      if (!isAnyPlaying || _streamToken != token) {
        try {
          proc.kill(ProcessSignal.sigterm);
        } catch (_) {}
        return;
      }

      _linuxProcess = proc;
      proc.stdin.done.ignore();

      final sw = Stopwatch()..start();
      int samplesSent = 0;
      final int prebufferSamples = (sampleRate * 0.14).round();
      final int maxChunkSamples = (sampleRate * 0.25).round();

      void feedMixedSlices() {
        if (!isAnyPlaying || _streamToken != token || _linuxProcess != proc) {
          return;
        }
        final elapsedSamples = (sw.elapsedMicroseconds * sampleRate) ~/ 1000000;
        final targetSamples = elapsedSamples + prebufferSamples;
        int count = targetSamples - samplesSent;
        if (count <= 0) return;
        if (count > maxChunkSamples) {
          samplesSent = targetSamples - prebufferSamples;
          count = prebufferSamples;
        }

        final outBytes = mixActivePcmSamples(count);

        try {
          proc!.stdin.add(outBytes);
          samplesSent += count;
        } catch (_) {}
      }

      feedMixedSlices();
      _linuxFeedTimer = Timer.periodic(
        const Duration(milliseconds: 35),
        (_) => feedMixedSlices(),
      );
    } catch (e) {
      debugPrint('AmbientSoundService Linux multi-track mixer error: $e');
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
