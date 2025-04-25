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

    // Physics-based trajectory
    final startOffset = Offset(0.0, 1.0);
    final endOffset = widget.shotMade
        ? Offset(0.0, -1.95)
        : [
            Offset(-0.2, -2.5), // Base value
            Offset(-0.2 * Random().nextDouble().clamp(0.9, 1.1),
                -2.5 * Random().nextDouble().clamp(0.9, 1.1)),
            Offset(-0.2 * Random().nextDouble().clamp(0.9, 1.1),
                -2.5 * Random().nextDouble().clamp(0.9, 1.1)),
          ][Random().nextInt(3)];

    final groundPoint =
        widget.shotMade ? Offset(0.0, 1.0) : Offset(endOffset.dx * 4, 1.0);

    // Physics parameters
    const double g =
        10.0; // Gravity in Flutter units/s² (positive, pulls downward)
    final double tPeak = widget.shotMade ? 1.3 : 1.6; // Time to reach endOffset
    final double tTotal = 2.0; // Total duration in seconds

    // Calculate initial velocities to hit endOffset at tPeak
    final double vx0 = (endOffset.dx - startOffset.dx) / tPeak;
    final double vy0 =
        (endOffset.dy - startOffset.dy - 0.5 * g * tPeak * tPeak) / tPeak;

    // For missed shots, calculate velocity at tPeak to reach groundPoint by tTotal
    final double tGround = tTotal - tPeak; // Time from endOffset to groundPoint
    final double vxGround =
        widget.shotMade ? 0.0 : (groundPoint.dx - endOffset.dx) / tGround;
    final double vyGround = widget.shotMade
        ? 0.0
        : (groundPoint.dy - endOffset.dy - 0.5 * g * tGround * tGround) /
            tGround;

    _trajectory = _PhysicsAnimation(
      controller: _controller,
      startOffset: startOffset,
      vx0: vx0,
      vy0: vy0,
      vxGround: vxGround,
      vyGround: vyGround,
      g: g,
      tPeak: tPeak,
      tTotal: tTotal,
    );

    // Scale animation: from 1.1 to 0.75
    _scale = Tween<double>(
      begin: 1.1,
      end: 0.75,
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

// Custom physics-based animation
class _PhysicsAnimation extends Animation<Offset>
    with AnimationWithParentMixin<double> {
  final Offset startOffset;
  final double vx0;
  final double vy0;
  final double vxGround;
  final double vyGround;
  final double g;
  final double tPeak;
  final double tTotal;
  final Animation<double> _parent;

  _PhysicsAnimation({
    required AnimationController controller,
    required this.startOffset,
    required this.vx0,
    required this.vy0,
    required this.vxGround,
    required this.vyGround,
    required this.g,
    required this.tPeak,
    required this.tTotal,
  }) : _parent = controller;

  @override
  Animation<double> get parent => _parent;

  @override
  Offset get value {
    final t = _parent.value * tTotal; // Scale to total duration (2s)
    if (t <= tPeak) {
      // Initial trajectory to endOffset
      final x = startOffset.dx + vx0 * t;
      final y = startOffset.dy + vy0 * t + 0.5 * g * t * t;
      return Offset(x, y);
    } else {
      // From endOffset to groundPoint (only for missed shots)
      final tGround = t - tPeak;
      final x = startOffset.dx + vx0 * tPeak + vxGround * tGround;
      final y = startOffset.dy +
          vy0 * tPeak +
          0.5 * g * tPeak * tPeak +
          vyGround * tGround +
          0.5 * g * tGround * tGround;
      return Offset(x, y);
    }
  }
}
