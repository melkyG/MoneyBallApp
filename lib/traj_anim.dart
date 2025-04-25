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
  late Animation<double> _bounce;
  late double _vxGround; // Store vxGround for rolling effect
  late double _tTotal; // Store tTotal for bounce and roll calculations

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration:
          const Duration(milliseconds: 3500), // Extended for pronounced bounce
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onAnimationComplete();
        }
      });

    // Physics-based trajectory
    final startOffset = Offset(-1.1, 1.15);
    final endOffset = widget.shotMade
        ? Offset(0.0, -1.95)
        : [
            Offset(-0.2, -2.5), // Base value
            Offset(0.3, -2.4),
            Offset(-0.25, -2.7),
          ][Random().nextInt(3)];

    final groundPoint =
        Offset(endOffset.dx * 4, 1.0); // Same groundPoint for both

    // Physics parameters
    const double g =
        10.0; // Gravity in Flutter units/s² (positive, pulls downward)
    final double tPeak = widget.shotMade ? 1.3 : 1.6; // Time to reach endOffset
    _tTotal =
        2.0; // Total duration in seconds for trajectory, stored as instance variable

    // Calculate initial velocities to hit endOffset at tPeak
    final double vx0 = (endOffset.dx - startOffset.dx) / tPeak;
    final double vy0 =
        (endOffset.dy - startOffset.dy - 0.5 * g * tPeak * tPeak) / tPeak;

    // Calculate velocity from endOffset to groundPoint for both made and missed shots
    final double tGround =
        _tTotal - tPeak; // Time from endOffset to groundPoint
    _vxGround = (groundPoint.dx - endOffset.dx) / tGround; // Store for rolling
    final double vyGround =
        (groundPoint.dy - endOffset.dy - 0.5 * g * tGround * tGround) / tGround;

    _trajectory = _PhysicsAnimation(
      controller: _controller,
      startOffset: startOffset,
      vx0: vx0,
      vy0: vy0,
      vxGround: _vxGround,
      vyGround: vyGround,
      g: g,
      tPeak: tPeak,
      tTotal: _tTotal,
      shotMade: widget.shotMade,
    );

    // Scale animation: from 0.45 to 0.25 until ground, then hold
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.45, end: 0.25).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: _tTotal / 3.5 * 100, // Scale until tTotal (2s)
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 0.25), // Hold scale at 0.25
        weight: (1.0 - _tTotal / 3.5) * 100, // Remainder of animation
      ),
    ]).animate(_controller);

    // Bounce animation: pronounced vertical oscillation with higher first bounce
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.5).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.5, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.3).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.3, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.2).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.2, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 10.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _tTotal / 3.5, // Start bounce when ball reaches groundPoint
        1.0,
        curve: Curves.linear,
      ),
    ));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate rolling offset during bounce phase
        final double bounceProgress =
            (_controller.value - _tTotal / 3.5) / (1.0 - _tTotal / 3.5);
        final double rollOffset = _controller.value >= _tTotal / 3.5
            ? _vxGround *
                bounceProgress *
                75 *
                0.5 // Roll in direction of vxGround
            : 0.0;

        return Transform.translate(
          offset: Offset(
            _trajectory.value.dx * 75 + rollOffset, // Add rolling offset
            _trajectory.value.dy * 75 + _bounce.value * 100,
          ),
          child: Transform.scale(
            scale: _scale.value,
            child: Image.asset(
              "assets/images/ball.png",
              width: 8,
              height: 8,
              fit: BoxFit.contain,
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
  final bool shotMade;
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
    required this.shotMade,
  }) : _parent = controller;

  @override
  Animation<double> get parent => _parent;

  @override
  Offset get value {
    final t = _parent.value * 3.5; // Scale to total animation duration (3.5s)
    if (t <= tPeak) {
      // Initial trajectory to endOffset
      final x = startOffset.dx + vx0 * t;
      final y = startOffset.dy + vy0 * t + 0.5 * g * t * t;
      return Offset(x, y);
    } else {
      // From endOffset to groundPoint for both made and missed shots
      final tGround = min(t - tPeak, tTotal - tPeak); // Cap at groundPoint time
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
