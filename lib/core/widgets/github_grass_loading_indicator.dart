import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GitHubGrassLoadingIndicator extends StatefulWidget {
  const GitHubGrassLoadingIndicator({
    super.key,
    this.width = 160,
    this.height = 48,
    this.tileSize = 18,
    this.spacing = 6,
    this.tileColor = AppTheme.primaryColor,
    this.checkColor = const Color(0xFF2EA043),
    this.duration = const Duration(milliseconds: 1400),
  });

  final double width;
  final double height;
  final double tileSize;
  final double spacing;
  final Color tileColor;
  final Color checkColor;
  final Duration duration;

  @override
  State<GitHubGrassLoadingIndicator> createState() =>
      _GitHubGrassLoadingIndicatorState();
}

class _GitHubGrassLoadingIndicatorState
    extends State<GitHubGrassLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant GitHubGrassLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _tileProgress(int index, double value) {
    const stagger = 0.18 / 1.4;
    const popDuration = 0.32;
    final start = index * stagger;
    return ((value - start) / popDuration).clamp(0.0, 1.0);
  }

  double _checkProgress(double value) {
    const start = 0.7;
    const duration = 0.18;
    return ((value - start) / duration).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                final tileProgress = _tileProgress(index, progress);
                final bounce = math.sin(tileProgress * math.pi);
                final scale = 0.72 + (tileProgress * 0.28) + (bounce * 0.13);
                final translateY = ((1 - tileProgress) * 7) - (bounce * 5);
                final opacity = (tileProgress * 1.4).clamp(0.0, 1.0);
                final tile = _LoadingTile(
                  size: widget.tileSize,
                  color: widget.tileColor,
                  checkColor: widget.checkColor,
                  checkProgress: index == 3 ? _checkProgress(progress) : 0,
                );

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == 3 ? 0 : widget.spacing,
                  ),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: Transform.scale(scale: scale, child: tile),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile({
    required this.size,
    required this.color,
    required this.checkColor,
    required this.checkProgress,
  });

  final double size;
  final Color color;
  final Color checkColor;
  final double checkProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size * 0.17),
            ),
            child: const SizedBox.expand(),
          ),
          if (checkProgress > 0)
            CustomPaint(
              size: Size.square(size),
              painter: _CheckmarkPainter(
                color: checkColor,
                progress: checkProgress,
              ),
            ),
        ],
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  const _CheckmarkPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final firstStart = Offset(size.width * 0.26, size.height * 0.52);
    final corner = Offset(size.width * 0.43, size.height * 0.68);
    final end = Offset(size.width * 0.76, size.height * 0.33);

    if (progress <= 0.42) {
      final localProgress = progress / 0.42;
      canvas.drawLine(
        firstStart,
        Offset.lerp(firstStart, corner, localProgress)!,
        paint,
      );
      return;
    }

    canvas.drawLine(firstStart, corner, paint);
    final localProgress = (progress - 0.42) / 0.58;
    canvas.drawLine(corner, Offset.lerp(corner, end, localProgress)!, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
