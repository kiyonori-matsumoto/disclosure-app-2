import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate feature_graphic.png (1024x500)', () async {
    const width = 1024;
    const height = 500;

    // Load Noto Sans JP font
    final fontLoader = FontLoader('NotoSansJP');
    final fontBytes = await File('fonts/NotoSansJP-Variable.ttf').readAsBytes();
    fontLoader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
    await fontLoader.load();

    // Load icon
    final iconBytes = await File('icons/icon_console.png').readAsBytes();
    final iconCodec = await ui.instantiateImageCodec(iconBytes);
    final iconFrame = await iconCodec.getNextFrame();
    final iconImage = iconFrame.image;

    // Load screenshot
    final ssBytes = await File('docs/store/screenshots/01_timeline_tdnet.png').readAsBytes();
    final ssCodec = await ui.instantiateImageCodec(ssBytes);
    final ssFrame = await ssCodec.getNextFrame();
    final ssImage = ssFrame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));

    // 1. Background Gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(1024.0, 500.0),
        const [
          Color(0xFF0A1128),
          Color(0xFF001F54),
          Color(0xFF034078),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    // Glow top right
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(870, 100),
        350,
        [
          const Color(0xFF00B4D8).withValues(alpha: 0.35),
          const Color(0xFF00B4D8).withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), glowPaint);

    // Subtle Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (double y = 125; y < height; y += 125) {
      canvas.drawLine(Offset(0, y), Offset(width.toDouble(), y), gridPaint);
    }
    for (double x = 256; x < width; x += 256) {
      canvas.drawLine(Offset(x, 0), Offset(x, height.toDouble()), gridPaint);
    }

    // 2. Right Side: Real Phone Screenshot Mockup
    canvas.save();
    canvas.translate(680, 25);
    canvas.rotate(4 * math.pi / 180);

    const phoneWidth = 270.0;
    const phoneHeight = 580.0;
    const cornerRadius = 36.0;

    // Outer shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-8, 8, phoneWidth + 16, phoneHeight + 16),
        const Radius.circular(44),
      ),
      shadowPaint,
    );

    // Outer Bezel
    final bezelPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-8, -8, phoneWidth + 16, phoneHeight + 16),
        const Radius.circular(44),
      ),
      bezelPaint,
    );
    final borderPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-8, -8, phoneWidth + 16, phoneHeight + 16),
        const Radius.circular(44),
      ),
      borderPaint,
    );

    // Screen Clip
    final screenRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, phoneWidth, phoneHeight),
      const Radius.circular(cornerRadius),
    );
    canvas.save();
    canvas.clipRRect(screenRRect);

    // Draw real screenshot
    final srcRect = Rect.fromLTWH(
      0,
      0,
      ssImage.width.toDouble(),
      ssImage.width.toDouble() * (phoneHeight / phoneWidth),
    );
    final dstRect = Rect.fromLTWH(0, 0, phoneWidth, phoneHeight);
    canvas.drawImageRect(ssImage, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);

    canvas.restore(); // restore clip

    // Inner highlight
    final innerHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(screenRRect, innerHighlight);

    canvas.restore(); // restore phone transform

    // 3. Left Side: App Icon, Branding & Copy
    canvas.save();
    canvas.translate(64, 70);

    // Icon Shadow
    final iconShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 4, 76, 76),
        const Radius.circular(18),
      ),
      iconShadowPaint,
    );

    // Icon Image
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 76, 76),
        const Radius.circular(18),
      ),
    );
    canvas.drawImageRect(
      iconImage,
      Rect.fromLTWH(0, 0, iconImage.width.toDouble(), iconImage.height.toDouble()),
      const Rect.fromLTWH(0, 0, 76, 76),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    // App Title
    final tpTitle = TextPainter(
      text: const TextSpan(
        text: '適時開示 Notifier',
        style: TextStyle(
          fontFamily: 'NotoSansJP',
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpTitle.paint(canvas, const Offset(96, 6));

    // Sub Title
    final tpSubTitle = TextPainter(
      text: const TextSpan(
        text: 'TDNET & EDINET NOTIFIER',
        style: TextStyle(
          fontFamily: 'NotoSansJP',
          color: Color(0xFF90E0EF),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSubTitle.paint(canvas, const Offset(96, 42));

    // Main Catchphrase Line 1
    final tpMain1 = TextPainter(
      text: const TextSpan(
        text: '適時開示 & EDINETを',
        style: TextStyle(
          fontFamily: 'NotoSansJP',
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpMain1.paint(canvas, const Offset(0, 115));

    // Main Catchphrase Line 2
    final tpMain2 = TextPainter(
      text: const TextSpan(
        text: '最速プッシュ通知。',
        style: TextStyle(
          fontFamily: 'NotoSansJP',
          color: Color(0xFF48CAE4),
          fontSize: 44,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpMain2.paint(canvas, const Offset(0, 172));

    // Sub Copy
    final tpSubCopy = TextPainter(
      text: const TextSpan(
        text: '保有銘柄の開示・決算発表を逃さない',
        style: TextStyle(
          fontFamily: 'NotoSansJP',
          color: Color(0xFFCBD5E1),
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSubCopy.paint(canvas, const Offset(0, 240));

    // 4. Feature Badges with 100% Vector Icons (Never corrupts or tofu)
    void drawBadge({
      required String label,
      required double xOffset,
      required void Function(Canvas c, Offset o, Color col) drawIcon,
    }) {
      const badgeHeight = 38.0;
      final tpLabel = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontFamily: 'NotoSansJP',
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Icon (18px) + space (8px) + text + horizontal paddings (16px * 2)
      final badgeWidth = 16.0 + 18.0 + 8.0 + tpLabel.width + 16.0;
      final badgeRect = Rect.fromLTWH(xOffset, 290, badgeWidth, badgeHeight);
      final rrect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(19));

      // Badge Background & Border
      final bg = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = const Color(0xFF48CAE4).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRRect(rrect, bg);
      canvas.drawRRect(rrect, border);

      // Draw Vector Icon (Vertical Centered)
      final iconOffset = Offset(xOffset + 15, 290 + (badgeHeight - 18) / 2);
      drawIcon(canvas, iconOffset, const Color(0xFF48CAE4));

      // Draw Label
      tpLabel.paint(
        canvas,
        Offset(xOffset + 16 + 18 + 8, 290 + (badgeHeight - tpLabel.height) / 2),
      );
    }

    // Vector Icon 1: Lightning Bolt (⚡)
    void drawBolt(Canvas c, Offset o, Color col) {
      final path = Path()
        ..moveTo(o.dx + 11, o.dy + 0.5)
        ..lineTo(o.dx + 3, o.dy + 9.5)
        ..lineTo(o.dx + 9, o.dy + 9.5)
        ..lineTo(o.dx + 6, o.dy + 17.5)
        ..lineTo(o.dx + 16, o.dy + 7.5)
        ..lineTo(o.dx + 10, o.dy + 7.5)
        ..close();
      c.drawPath(path, Paint()..color = col..style = PaintingStyle.fill);
    }

    // Vector Icon 2: PDF Document (📑)
    void drawDocument(Canvas c, Offset o, Color col) {
      final docRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx + 2, o.dy + 1, 13, 16),
        const Radius.circular(2.5),
      );
      c.drawRRect(
        docRRect,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      final linePaint = Paint()
        ..color = col
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(o.dx + 5.5, o.dy + 6.5), Offset(o.dx + 11.5, o.dy + 6.5), linePaint);
      c.drawLine(Offset(o.dx + 5.5, o.dy + 10.5), Offset(o.dx + 11.5, o.dy + 10.5), linePaint);
    }

    // Vector Icon 3: Calendar (📅)
    void drawCalendar(Canvas c, Offset o, Color col) {
      final calRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx + 1.5, o.dy + 3, 15, 14),
        const Radius.circular(2.5),
      );
      c.drawRRect(
        calRRect,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      // Top header divider
      c.drawLine(
        Offset(o.dx + 1.5, o.dy + 7.5),
        Offset(o.dx + 16.5, o.dy + 7.5),
        Paint()
          ..color = col
          ..strokeWidth = 1.4,
      );
      // Top pins
      final pinPaint = Paint()
        ..color = col
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(o.dx + 5.5, o.dy + 1), Offset(o.dx + 5.5, o.dy + 4), pinPaint);
      c.drawLine(Offset(o.dx + 12.5, o.dy + 1), Offset(o.dx + 12.5, o.dy + 4), pinPaint);
      // Dot
      c.drawCircle(Offset(o.dx + 9, o.dy + 11), 1.3, Paint()..color = col);
    }

    drawBadge(label: '最速リアルタイム', xOffset: 0, drawIcon: drawBolt);
    drawBadge(label: '原文PDF即時閲覧', xOffset: 160, drawIcon: drawDocument);
    drawBadge(label: '決算カレンダー', xOffset: 326, drawIcon: drawCalendar);

    canvas.restore(); // restore left content transform

    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final outputFile = File('docs/store/feature_graphic.png');
    await outputFile.writeAsBytes(pngBytes);
    print('Successfully generated ${outputFile.path} (${pngBytes.length} bytes)');
    expect(pngBytes.length, greaterThan(1000));
    expect(pngBytes.length, lessThan(15 * 1024 * 1024));
  });
}
