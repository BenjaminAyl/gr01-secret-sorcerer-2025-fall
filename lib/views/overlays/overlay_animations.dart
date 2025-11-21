import 'dart:async';
import 'package:flutter/material.dart';

class StaggerFadeScale extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;
  final double beginScale;
  final double endScale;

  const StaggerFadeScale({
    super.key,
    required this.child,
    required this.delayMs,
    required this.durationMs,
    this.beginScale = 0.9,
    this.endScale = 1.0,
  });

  @override
  State<StaggerFadeScale> createState() => _StaggerFadeScaleState();
}

class _StaggerFadeScaleState extends State<StaggerFadeScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );
    _scale = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // Start after delay
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
