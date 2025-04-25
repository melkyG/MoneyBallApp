import 'package:flutter/material.dart';
import 'realistic_net_painter.dart'; // Import the painter

class AnimatedBasketballNet extends StatefulWidget {
  final double width;
  final double height;
  final bool triggerSwish; // Trigger animation from outside
  final int delayInMilliseconds; // Time delay before triggering animation

  const AnimatedBasketballNet({
    super.key,
    this.width = 40,
    this.height = 60,
    required this.triggerSwish,
    this.delayInMilliseconds = 600, // Default delay of 300 ms
  });

  @override
  State<AnimatedBasketballNet> createState() => _AnimatedBasketballNetState();
}

class _AnimatedBasketballNetState extends State<AnimatedBasketballNet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _isAnimating = false;
  bool _delayedTrigger = false; // Flag to control delayed trigger

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedBasketballNet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only trigger animation if `triggerSwish` changes to true
    if (widget.triggerSwish &&
        !oldWidget.triggerSwish &&
        !_isAnimating &&
        !_delayedTrigger) {
      // Start the delay before the animation begins
      _delayedTrigger = true;
      Future.delayed(Duration(milliseconds: widget.delayInMilliseconds), () {
        if (mounted) {
          _controller.reset(); // Reset the animation controller
          _controller.forward(); // Start the animation from the beginning
          setState(() {
            _isAnimating = true;
          });
        }
      });
    }

    // Reset the isAnimating flag when animation completes
    if (!widget.triggerSwish && _isAnimating) {
      setState(() {
        _isAnimating = false;
        _delayedTrigger = false; // Allow future animations
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          alignment: Alignment.topCenter,
          scaleY: _scaleAnimation.value,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: RealisticNetPainter(), // Use the painter here
      ),
    );
  }
}
