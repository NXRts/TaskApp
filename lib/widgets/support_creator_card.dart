import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/external_link_helper.dart';

/// Descriptor for a creator support / donation platform link.
class SupportLinkItem {
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;
  final Color accentColor;

  const SupportLinkItem({
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
    required this.accentColor,
  });
}

/// Editorial card presenting creator support options (Saweria, Ko-fi, Yapp.ink).
class SupportCreatorCard extends StatelessWidget {
  final Future<bool> Function(String url)? launcherOverride;

  const SupportCreatorCard({
    super.key,
    this.launcherOverride,
  });

  static const List<SupportLinkItem> defaultLinks = [
    SupportLinkItem(
      title: 'Saweria',
      subtitle: 'saweria.co/yusufarrofi • QRIS, GoPay, OVO, DANA',
      url: 'https://saweria.co/yusufarrofi',
      icon: Icons.volunteer_activism_outlined,
      accentColor: AppTheme.warningOchre,
    ),
    SupportLinkItem(
      title: 'Ko-fi',
      subtitle: 'ko-fi.com/yusufarrofi • Traktir kopi pengembang',
      url: 'https://ko-fi.com/yusufarrofi/',
      icon: Icons.local_cafe_outlined,
      accentColor: AppTheme.brandCobalt,
    ),
    SupportLinkItem(
      title: 'Yapp.ink',
      subtitle: 'yapp.ink/yusufarrofi21 • Tautan dukungan & kreator',
      url: 'https://yapp.ink/yusufarrofi21',
      icon: Icons.favorite_outline_rounded,
      accentColor: AppTheme.successSage,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final borderCol = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final surfaceElevated = isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightBorderSubtle;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.urgentRose.withValues(alpha: isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: AppTheme.urgentRose.withValues(alpha: 0.28),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: AppTheme.urgentRose,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dukung Pengembangan TaskApp',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'TaskApp 100% gratis, offline-first, dan bebas iklan. Jika aplikasi ini membantu perkuliahan Anda, dukungan Anda sangat berarti.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: borderCol.withValues(alpha: 0.6), height: 1),
          for (int i = 0; i < defaultLinks.length; i++) ...[
            _buildLinkTile(
              context,
              item: defaultLinks[i],
              isDark: isDark,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              surfaceElevated: surfaceElevated,
            ),
            if (i < defaultLinks.length - 1)
              Divider(color: borderCol.withValues(alpha: 0.45), height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required SupportLinkItem item,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color surfaceElevated,
  }) {
    return InkWell(
      onTap: () => ExternalLinkHelper.openUrl(
        context,
        item.url,
        label: item.title,
        launcherOverride: launcherOverride,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 17, color: item.accentColor),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              tooltip: 'Salin tautan ${item.title}',
              icon: Icon(Icons.copy_rounded, size: 15, color: textSecondary),
              onPressed: () => ExternalLinkHelper.copyUrl(
                context,
                item.url,
                label: item.title,
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.open_in_new_rounded, size: 14, color: item.accentColor),
            ),
          ],
        ),
      ),
    );
  }
}
