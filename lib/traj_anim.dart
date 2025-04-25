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
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete();
        }
      });

    // Trajectory animation
    final endOffset = widget.shotMade
        ? Offset(0.0, -1.95)
        : [
            Offset(-0.2, -2.5), // Base value
            Offset(0.2, -2.5), // Base value
            Offset(-0.2, -2.7), // Base value
          ][Random().nextInt(3)];

    // Define intermediate point (peak of the arc)
    final midPoint = widget.shotMade
        ? Offset(0.0, -2.1) // Higher peak for made shots
        : Offset(endOffset.dx / 2, -2.8); // Midpoint adjusted for missed shots

    final groundPoint = widget.shotMade
        ? Offset(0.0, 1.0)
        : Offset(endOffset.dx * 4, 1.0); // adjusted for missed shots

    _trajectory = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset(0.0, 1.0), // Start near bottom
          end: midPoint, // Peak of arc
        ),
        weight: 65.0, // 50% of animation time to reach peak
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: midPoint, // From peak
          end: endOffset, // To final endpoint
        ),
        weight: 15.0, // 50% of animation time to descend
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: endOffset, // From peak
          end: groundPoint, // To final endpoint
        ),
        weight: 20.0, // 50% of animation time to descend
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Scale animation: from 1.1 to 0.75
    _scale = Tween<double>(
      begin: 1.1, // Full size at start
      end: 0.75, // 75% size at end
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
            scale: _scale.value,
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
