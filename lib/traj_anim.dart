import 'package:flutter/material.dart';
import 'dart:math';

class BallTrajectory extends StatefulWidget {
  final bool shotMade;
  final double releaseDifference;
  final VoidCallback onAnimationComplete;

  BallTrajectory({
    required this.shotMade,
    required this.releaseDifference,
    required this.onAnimationComplete,
  });

  @override
  _BallTrajectoryState createState() => _BallTrajectoryState();
}

class _BallTrajectoryState extends State<BallTrajectory>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _trajectory;
  late Animation<double> _scale; // Added for scaling animation

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete();
        }
      });

    // Trajectory animation
    _trajectory = Tween<Offset>(
      begin: Offset(0.0, 1.0), // Start near bottom
      end: widget.shotMade
          ? Offset(0.0, -1.95)
          : [
              Offset(-0.2, -2.5), // Base value
              Offset(0.2, -3.0), // Base value
              Offset(0.5, -2.4), // Base value
            ][Random().nextInt(3)],
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Scale animation: from 1.0 to 0.8
    _scale = Tween<double>(
      begin: 1.1, // Full size at start
      end: 0.75, // 75% size at end
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut, // Same curve as trajectory for smoothness
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _trajectory.value * 75,
          child: Transform.scale(
            scale: _scale.value, // Apply scale animation
            child: Image.asset(
              "assets/images/ball.png",
              width: 24,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
