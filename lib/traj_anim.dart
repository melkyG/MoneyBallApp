import 'package:flutter/material.dart';

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

class _BallTrajectoryState extends State<BallTrajectory> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _trajectory;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete();
        }
      });

    // Example curve: you can replace this with Bezier or physics-based
    _trajectory = Tween<Offset>(
      begin: Offset(0.0, 1.0), // Start near bottom
      end: widget.shotMade ? Offset(0.0, 0.0) : Offset(-0.3, 0.1),
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
        return Positioned(
          left: 162, // Adjust based on game layout
          top: 500,  // Starting point of ball
          child: Transform.translate(
            offset: _trajectory.value * 300, // Adjust multiplier as needed
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