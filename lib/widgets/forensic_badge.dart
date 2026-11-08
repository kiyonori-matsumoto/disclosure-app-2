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

        _pulseAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
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
      final firstTag = presenter.tagInfos.first.displayName;
      final extraCount = presenter.tagInfos.length - 1;
      label = extraCount > 0 ? '$firstTag +$extraCount' : firstTag;
    } else {
      if (isCritical) {
        label = '🚨 重要項目検知';
      } else if (isWarning) {
        label = '⚠️ 特記事項あり';
      } else {
        label = '✓ 特記事項なし';
      }
    }

    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isCritical) {
      bgColor = Colors.red.shade100;
      borderColor = Colors.red.shade600;
      textColor = Colors.red.shade900;
    } else if (isWarning) {
      bgColor = Colors.orange.shade100;
      borderColor = Colors.orange.shade600;
      textColor = Colors.deepOrange.shade900;
    } else {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade400;
      textColor = Colors.green.shade900;
    }

    Widget badgeContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        showForensicDetailSheet(
          context: context,
          forensic: forensic,
          companyName: widget.companyName,
          documentTitle: widget.documentTitle,
        );
      },
      child: Padding(
        // 見た目のコンパクトさを保ちつつ、誤タップを防ぐための透明タッチターゲット領域
        padding: const EdgeInsets.only(top: 4.0, bottom: 6.0, right: 8.0),
        child: Container(
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
            ],
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
