import 'package:flutter/material.dart';
import '../models/forensic_result.dart';
import '../utils/forensic_ui_presenter.dart';
import 'forensic_detail_sheet.dart';

class ForensicBadge extends StatefulWidget {
  final ForensicResult? forensic;
  final String? companyName;
  final String? documentTitle;
  final bool enableAnimation;

  const ForensicBadge({
    super.key,
    required this.forensic,
    this.companyName,
    this.documentTitle,
    this.enableAnimation = true,
  });

  @override
  State<ForensicBadge> createState() => _ForensicBadgeState();
}

class _ForensicBadgeState extends State<ForensicBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimationIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ForensicBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forensic?.riskLevel != oldWidget.forensic?.riskLevel) {
      _setupAnimationIfNeeded();
    }
  }

  void _setupAnimationIfNeeded() {
    if (widget.enableAnimation &&
        widget.forensic?.riskLevel == ForensicRiskLevel.critical) {
      if (_pulseController == null) {
        _pulseController = AnimationController(
          duration: const Duration(milliseconds: 1400),
          vsync: this,
        )..repeat(reverse: true);

        // 控えめで落ち着いたフェードアニメーション
        _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(
            parent: _pulseController!,
            curve: Curves.easeInOut,
          ),
        );
      }
    } else {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseAnimation = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forensic = widget.forensic;
    if (forensic == null) {
      return const SizedBox.shrink();
    }

    final presenter = ForensicUiPresenter(forensic);
    final isCritical = forensic.riskLevel == ForensicRiskLevel.critical;
    final isWarning = forensic.riskLevel == ForensicRiskLevel.warning;

    // バッジラベルの決定
    String label;
    if (presenter.tagInfos.isNotEmpty) {
      final firstTag = presenter.tagInfos.first;
      String tagName = firstTag.displayName;

      // アイコンと重大度の整合性ガード (案A: 通常 < 乖離あり ⚠️ < 大幅乖離 ❗)
      if (isCritical) {
        if (tagName.startsWith('⚠️ ')) {
          tagName = '❗ ${tagName.substring(3)}';
        } else if (tagName.startsWith('🚨 ')) {
          tagName = '❗ ${tagName.substring(3)}';
        }
      } else if (isWarning) {
        if (tagName.startsWith('❗ ')) {
          tagName = '⚠️ ${tagName.substring(3)}';
        } else if (tagName.startsWith('🚨 ')) {
          tagName = '⚠️ ${tagName.substring(3)}';
        }
      }

      final extraCount = presenter.tagInfos.length - 1;
      label = extraCount > 0 ? '$tagName +$extraCount' : tagName;
    } else {
      if (isCritical) {
        label = '❗ 大幅乖離';
      } else if (isWarning) {
        label = '⚠️ 乖離あり';
      } else {
        label = '✓ 通常';
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isCritical) {
      bgColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.35)
          : Colors.red.shade100;
      borderColor = isDark ? Colors.red.shade400 : Colors.red.shade600;
      textColor = isDark ? Colors.red.shade200 : Colors.red.shade900;
    } else if (isWarning) {
      bgColor = isDark
          ? Colors.orange.shade900.withValues(alpha: 0.35)
          : Colors.orange.shade100;
      borderColor = isDark ? Colors.orange.shade400 : Colors.orange.shade600;
      textColor = isDark ? Colors.orange.shade200 : Colors.deepOrange.shade900;
    } else {
      bgColor = isDark
          ? Colors.green.shade900.withValues(alpha: 0.35)
          : Colors.green.shade50;
      borderColor = isDark ? Colors.green.shade400 : Colors.green.shade400;
      textColor = isDark ? Colors.green.shade200 : Colors.green.shade900;
    }

    void openDetailSheet() {
      showForensicDetailSheet(
        context: context,
        forensic: forensic,
        companyName: widget.companyName,
        documentTitle: widget.documentTitle,
      );
    }

    Widget badgeContent = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: textColor.withValues(alpha: 0.16),
        highlightColor: textColor.withValues(alpha: 0.08),
        onTap: openDetailSheet,
        child: Padding(
          // 見た目のコンパクトさを保ちつつ、誤タップを防ぐための透明タッチターゲット領域
          padding: const EdgeInsets.only(top: 4.0, bottom: 6.0, right: 8.0),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 11,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isCritical && _pulseAnimation != null) {
      return AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation!.value,
            child: child,
          );
        },
        child: badgeContent,
      );
    }

    return badgeContent;
  }
}
