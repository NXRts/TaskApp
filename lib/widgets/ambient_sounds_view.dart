import 'package:flutter/material.dart';
import '../services/ambient_sound_service.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';

/// Dedicated FocEase-style multi-track Ambient Sounds Mixer view,
/// separated from the Pomodoro Timer inside the Fokus tab.
class AmbientSoundsView extends StatefulWidget {
  const AmbientSoundsView({super.key});

  @override
  State<AmbientSoundsView> createState() => _AmbientSoundsViewState();
}

class _AmbientSoundsViewState extends State<AmbientSoundsView> {
  final AmbientSoundService _ambientService = AmbientSoundService.instance;

  static const Color _foceasePurple = Color(0xFFA855F7);
  static const Color _foceaseCardDark = Color(0xFF16181F);
  static const Color _foceaseTileDark = Color(0xFF1E212B);
  static const Color _foceaseButtonIdleDark = Color(0xFF151821);
  static const Color _foceaseSliderTrackDark = Color(0xFF15171E);

  void _onAmbientChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _ambientService.addListener(_onAmbientChanged);
  }

  @override
  void dispose() {
    _ambientService.removeListener(_onAmbientChanged);
    super.dispose();
  }

  StorageService? _tryGetStorage() {
    try {
      return StorageService.instance;
    } catch (_) {
      return null;
    }
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? _foceaseCardDark : Colors.white;
    final tileBg = isDark ? _foceaseTileDark : const Color(0xFFF4F5F8);
    final idleBtnBg = isDark ? _foceaseButtonIdleDark : const Color(0xFFE9ECF2);
    final inactiveSliderCol =
        isDark ? _foceaseSliderTrackDark : const Color(0xFFDADEE8);
    final borderCol =
        isDark ? const Color(0xFF262936) : AppTheme.lightBorder;
    final textPrimary =
        isDark ? Colors.white : AppTheme.lightTextPrimary;
    final textMuted =
        isDark ? const Color(0xFF8E95A9) : AppTheme.lightTextSecondary;

    final isAnyPlaying = _ambientService.isAnyPlaying;
    final activeCount = _ambientService.activePlayingCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FocEase Top Control Bar (Master Volume + Sleep Timer + Play All / Pause All + Reset)
          _buildTopMasterControls(
            context,
            isDark: isDark,
            cardBg: cardBg,
            tileBg: tileBg,
            inactiveSliderCol: inactiveSliderCol,
            borderCol: borderCol,
            textPrimary: textPrimary,
            textMuted: textMuted,
            isAnyPlaying: isAnyPlaying,
          ),

          const SizedBox(height: 14),

          // 2. Main "Ambient Sounds" Card matching https://focease.vercel.app/
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderCol, width: 0.9),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Glowing purple bar + "Ambient Sounds" + active count pill
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _foceasePurple,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: _foceasePurple.withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'Ambient Sounds',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (activeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _foceasePurple.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _foceasePurple.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '$activeCount Aktif',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _foceasePurple,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // All 9 FocEase Sound Track Cards
                for (int i = 0; i < AmbientSoundTrack.values.length; i++) ...[
                  if (i > 0) const SizedBox(height: 11),
                  _buildSoundTrackCard(
                    context,
                    track: AmbientSoundTrack.values[i],
                    isDark: isDark,
                    tileBg: tileBg,
                    idleBtnBg: idleBtnBg,
                    inactiveSliderCol: inactiveSliderCol,
                    borderCol: borderCol,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMasterControls(
    BuildContext context, {
    required bool isDark,
    required Color cardBg,
    required Color tileBg,
    required Color inactiveSliderCol,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
    required bool isAnyPlaying,
  }) {
    final masterVol = _ambientService.masterVolume;
    final timerDuration = _ambientService.timerDuration;
    final timeLeft = _ambientService.timeLeft;

    return Column(
      children: [
        // Master Volume Bar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol, width: 0.8),
          ),
          child: Row(
            children: [
              Icon(
                masterVol <= 0.01
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                size: 19,
                color: _foceasePurple,
              ),
              const SizedBox(width: 10),
              Text(
                'Master',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14.0,
                    ),
                    activeTrackColor: _foceasePurple,
                    inactiveTrackColor: inactiveSliderCol,
                    thumbColor: _foceasePurple,
                  ),
                  child: Slider(
                    value: masterVol,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      _ambientService.setMasterVolume(
                        val,
                        storage: _tryGetStorage(),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  '${(masterVol * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Timer Selector + Play All / Pause All + Reset Row
        Row(
          children: [
            // Timer Dropdown Pill
            Expanded(
              flex: 5,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 17,
                      color: timerDuration > 0
                          ? const Color(0xFF60A5FA)
                          : textMuted,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: AmbientTimerOption.options
                                  .any((o) => o.seconds == timerDuration)
                              ? timerDuration
                              : 0,
                          dropdownColor: isDark ? _foceaseTileDark : Colors.white,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: textMuted,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          items: AmbientTimerOption.options.map((opt) {
                            return DropdownMenuItem<int>(
                              value: opt.seconds,
                              child: Text(
                                opt.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _ambientService.setTimerDuration(
                                val,
                                storage: _tryGetStorage(),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    if (timeLeft > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        _formatCountdown(timeLeft),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Play All / Pause All Button
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 44,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isAnyPlaying
                          ? const [Color(0xFFD97706), Color(0xFFEA580C)]
                          : const [Color(0xFF9333EA), Color(0xFFDB2777)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (isAnyPlaying) {
                          _ambientService.stopAll();
                        } else {
                          _ambientService.playAll();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAnyPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                isAnyPlaying ? 'Pause All' : 'Play All',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Reset Button
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: cardBg,
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderCol, width: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  _ambientService.resetAll(storage: _tryGetStorage());
                },
                icon: Icon(Icons.restart_alt_rounded, size: 16, color: textMuted),
                label: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSoundTrackCard(
    BuildContext context, {
    required AmbientSoundTrack track,
    required bool isDark,
    required Color tileBg,
    required Color idleBtnBg,
    required Color inactiveSliderCol,
    required Color borderCol,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final isPlaying = _ambientService.isTrackPlaying(track);
    final volume = _ambientService.getTrackVolume(track);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isPlaying
              ? track.sliderColor.withValues(alpha: 0.42)
              : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // Left Rounded-Square Play / Pause Button (matches FocEase screenshot)
          GestureDetector(
            onTap: () => _ambientService.toggleSound(
              track,
              storage: _tryGetStorage(),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isPlaying ? track.activeBgColor : idleBtnBg,
                borderRadius: BorderRadius.circular(11),
                boxShadow: isPlaying
                    ? [
                        BoxShadow(
                          color: track.sliderColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 20,
                color: isPlaying ? Colors.white : textMuted,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Right Column: Track Icon + Name on top, Colored Volume Slider with white thumb below
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      track.icon,
                      size: 18,
                      color: isPlaying ? track.activeTextColor : textMuted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        track.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                          color: isPlaying ? textPrimary : textMuted,
                        ),
                      ),
                    ),
                    Text(
                      '${(volume * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isPlaying ? track.activeTextColor : textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7.5,
                      elevation: 2.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 13.0,
                    ),
                    activeTrackColor: track.sliderColor,
                    inactiveTrackColor: inactiveSliderCol,
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (val) {
                      _ambientService.setSoundVolume(
                        track,
                        val,
                        storage: _tryGetStorage(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
