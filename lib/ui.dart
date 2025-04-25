import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math'; // For pow() function
import 'game_logic.dart';
import 'traj_anim.dart';
import 'animated_basketball_net.dart';

class BasketballGame extends StatefulWidget {
  @override
  _BasketballGameState createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame>
    with TickerProviderStateMixin {
  late GameLogic gameLogic;
  String _currentMessage = "";
  Color _messageColor = Colors.white;
  bool _showMessage = false;
  bool showReadyBall = false;
  int shotSpamTimer = 1250;

  //traj
  bool showBallTrajectory = false;
  double releaseDifference = 0.0;
  DateTime? _lastShotTime;

  // Initial "ready" position for the ball (relative to 360x640 container)
  final double readyBallLeft = 160; // Centered: (360 - 40) / 2 ≈ 160
  final double readyBallTop = 450; // Near bottom for 3-point line perspective


  // Animation controller for uncover/cover
  late AnimationController _messageAnimController;
  late Animation<double> _messageAnimation;

  // Animation controller for sliding
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    gameLogic = GameLogic();
    gameLogic.initializeGame();

    // Initialize uncover/cover animation controller
    _messageAnimController = AnimationController(
      duration:
          const Duration(milliseconds: 600), // Total duration for sequence
      vsync: this,
    );
    _messageAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _messageAnimController,
        curve: const Interval(0.0, 0.14,
            curve: Curves.easeInOut), // Uncover: 0-150ms
      ),
    )..addListener(() {
        setState(() {});
      });

    // Initialize slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 275), // Slide in/out duration
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -200, end: 0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {});
      });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        gameLogic.showIntro = false;
      });
    });
  }

  @override
  void dispose() {
    _messageAnimController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Function to show and then hide release message with slide
  void showReleaseMessage(double releaseTime) {
    _messageAnimController.reset();
    _slideController.reset();

    setState(() {
      _showMessage = true;

      // Set appropriate message and color based on release time
      if (releaseTime >= -0.015 && releaseTime <= 0.015) {
        _currentMessage = "E x c e l l e n t";
        _messageColor = Color.fromARGB(255, 48, 245, 153);
      } else if (releaseTime > 0.015 && releaseTime <= 0.04) {
        _currentMessage = "Slightly  Late";
        _messageColor = Color.fromARGB(255, 197, 197, 197);
      } else if (releaseTime > 0.04 && releaseTime <= 0.07) {
        _currentMessage = "L a t e";
        _messageColor = Color.fromARGB(255, 233, 236, 17);
      } else if (releaseTime > 0.07) {
        _currentMessage = "V e r y  L a t e";
        _messageColor = Color.fromARGB(255, 255, 49, 49);
      } else if (releaseTime < -0.015 && releaseTime >= -0.04) {
        _currentMessage = "Slightly  Early";
        _messageColor = Color.fromARGB(255, 197, 197, 197);
      } else if (releaseTime < -0.04 && releaseTime >= -0.07) {
        _currentMessage = "E a r l y";
        _messageColor = Color.fromARGB(255, 233, 236, 17);
      } else if (releaseTime < -0.07) {
        _currentMessage = "V e r y  E a r l y";
        _messageColor = Color.fromARGB(255, 255, 49, 49);
      }
    });

    if (gameLogic.inGame) {
      // Start slide-in
      _slideController.forward();

      // Start uncover 100ms after slide-in begins
      Future.delayed(Duration(milliseconds: 220), () {
        _messageAnimController.forward().then((_) {
          // Pause, then cover and slide out
          Future.delayed(Duration(milliseconds: 600), () {
            // Adjusted for overlap
            _messageAnimController.reverse().then((_) {
              _slideController.reverse().then((_) {
                setState(() {
                  _showMessage = false;
                });
              });
            });
          });
        });
      });
    } else {
      setState(() {
        _showMessage = false;
      });
    }
  }

  // Build the animated message component
  Widget buildAnimatedMessage() {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Transform.translate(
          offset: Offset(_slideAnimation.value, 0), // Slide based on animation
          child: Stack(
            children: [
              // The message container
              Transform(
                transform: Matrix4.skewX(-0.2),
                child: Container(
                  margin: EdgeInsets.only(left: 25, bottom: 75),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.9),
                    border: Border.all(color: _messageColor, width: 1),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: _messageColor.withOpacity(0.8),
                        spreadRadius: 2,
                        offset: Offset(6, 3),
                      ),
                    ],
                  ),
                  child: Transform(
                    transform: Matrix4.skewX(0.2),
                    child: Text(
                      _currentMessage,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _messageColor,
                      ),
                    ),
                  ),
                ),
              ),

              // The covering animation (Right to Left)
              AnimatedBuilder(
                animation: _messageAnimController,
                builder: (context, child) {
                  double maxWidth = 200;
                  double coverWidth;
                  if (_messageAnimController.status ==
                          AnimationStatus.forward ||
                      _messageAnimController.status ==
                          AnimationStatus.completed) {
                    coverWidth = maxWidth * (1 - _messageAnimation.value);
                  } else {
                    coverWidth = maxWidth * (1 - _messageAnimation.value);
                  }
                  return Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Transform(
                        transform: Matrix4.skewX(-0.2),
                        child: Container(
                          margin: EdgeInsets.only(left: 25, bottom: 75),
                          height: 50,
                          width: coverWidth,
                          decoration: BoxDecoration(
                            color: _messageColor.withOpacity(1),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: null,
      body: Stack(
        children: [
          if (gameLogic.inGame) ...[
            Positioned.fill(
              child: Image.asset(
                "assets/images/background.png",
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 162,
              top: 189,
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/rim.png",
                    width: 40,
                  ),
                  Transform.translate(
                    offset: Offset(0, -12.5),
                    child: AnimatedBasketballNet(
                      width: 40,
                      height: 45,
                      triggerSwish: gameLogic.shotMade,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SafeArea(
            child: gameLogic.showIntro
                ? Center(
                    child: Text(
                      "Money Ball",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 48, 245, 179),
                      ),
                    ),
                  )
                : gameLogic.inGame
                    ? GestureDetector(
                        onPanStart: (_) {
                          final now = DateTime.now();
                          final canShoot = _lastShotTime == null || now.difference(_lastShotTime!).inMilliseconds >= shotSpamTimer;

                          if (gameLogic.shotsTaken < 27 && canShoot) {
                            setState((){});
                            gameLogic.startHolding(
                              () => setState(() {}),
                              () => gameLogic.startGameTimer(() => setState(() {})),
                            );
                          }
                        },

                        onPanEnd: (_) {
                          if (gameLogic.shotsTaken < 27) {
                            if (gameLogic.isHolding) {
                              print("releasing");
                              gameLogic.lastDifference =
                                  (gameLogic.heldTime - gameLogic.optimalTime).abs();
                              gameLogic.releaseShot(() {
                                setState(() {
                                  releaseDifference = gameLogic.lastDifferenceTrue;
                                  showBallTrajectory = true;
                                  showReadyBall = false;
                                  // Check if next shot is ready after 800ms
                                  Future.delayed(Duration(milliseconds: shotSpamTimer), () {
                                    final now = DateTime.now();
                                    final canShoot = _lastShotTime == null || now.difference(_lastShotTime!).inMilliseconds >= shotSpamTimer;
                                    if (canShoot && gameLogic.shotsTaken < 27) {
                                      setState(() {
                                        showReadyBall = true; // Show ball when next shot is ready
                                      });
                                    }
                                  });
                                  _lastShotTime = DateTime.now(); // 🕒 Mark the time the shot was made
                                });
                                showReleaseMessage(gameLogic.lastDifferenceTrue);
                              });
                            }
                          }
                        },

                        child: Container(
                          color: Colors.transparent,
                          width: double.infinity,
                          height: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 50.0),
                                  child: PulsingShotClock(
                                      timeLeft: gameLogic.timeLeft),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "Score: ${gameLogic.score}",
                                        style: TextStyle(
                                            fontSize: 24, color: Colors.white),
                                      ),
                                      Text(
                                        "${gameLogic.shotsTaken} / ${gameLogic.totalShots}",
                                        style: TextStyle(
                                            fontSize: 24, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (gameLogic.isHolding) buildShootingBar(),
                              SizedBox(height: 50),
                              // Remove BallTrajectory from here
                            ],
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (gameLogic.shotsTaken == gameLogic.totalShots ||
                                gameLogic.timeLeft == 0) ...[
                              Text(
                                "Times Up!",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Final Score: ${gameLogic.score}",
                                style: TextStyle(
                                    fontSize: 24, color: Colors.white),
                              ),
                            ],
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  gameLogic.startGame();
                                  showReadyBall = true; // Show ball when game starts
                                  _lastShotTime = null; // Reset shot time
                                });
                              },   
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 48, 245, 179),
                              ),
                              child: Text(
                                "Ready",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color.fromARGB(255, 67, 85, 78),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
          ),
          if (gameLogic.inGame || (gameLogic.shotsTaken > 0))
            buildShotIndicator(),
          if (_showMessage)
            ClipRect(
              child: buildAnimatedMessage(),
            ),
          // Add BallTrajectory here in the Stack
          if (showBallTrajectory)
            Align(
              alignment: Alignment.center, // Center the trajectory
              child: SizedBox(
                width: 100, // Constrain the container size
                height: 100,
                child: BallTrajectory(
                  shotMade: gameLogic.shotMade,
                  releaseDifference: releaseDifference,
                  onAnimationComplete: () {
                    setState(() {
                      showBallTrajectory = false;
                      // Check if shot is ready
                      final now = DateTime.now();
                      bool canShoot = _lastShotTime == null || now.difference(_lastShotTime!).inMilliseconds >= 800;
                      if (gameLogic.timeLeft > 0) {canShoot = false;}
                      if (canShoot && gameLogic.shotsTaken < 27 && gameLogic.timeLeft > 0) {
                        showReadyBall = true;
                      }
                    });
                  },
                ),
              ),
            ),
            if (showReadyBall)
              Positioned(
                bottom: 200,
                left: 80,
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/ball.png",
                      width: 32, // Adjust size as needed
                      height: 32,
                      fit: BoxFit.contain,
                        ),
                      ],
                    ),
                   ),
                  ],
                ),
              );
            }

  Widget buildShootingBar() {
    // Define the time range for the bar
    const double maxHoldTime = 1.85; // Maximum hold time for scaling
    const double barHeight = 250; // Height of the shooting bar
    const double barWidth = 40.0; // Width of the shooting bar

    // Fixed target band position (doesn't depend on time ranges anymore)
    double targetBandCenter =
        barHeight * 0.7; // Position at 70% of the bar height
    double targetBandHeight = 20.0; // Height of the target band
    double targetBandBottom = targetBandCenter - targetBandHeight / 2;

    // Calculate acceleration parameter based on optimalTime
    // Want the indicator to reach the targetBandCenter exactly at optimalTime
    double accelerationFactor =
        targetBandCenter / (pow(gameLogic.optimalTime, 2));

    // Calculate the current position of the moving indicator
    double heldTime = gameLogic.heldTime.clamp(0, maxHoldTime);
    double indicatorPosition = accelerationFactor * pow(heldTime, 2);
    indicatorPosition = indicatorPosition.clamp(0, barHeight);

    // Check if the indicator is within the target band
    //bool isInTargetZone = (indicatorPosition >= targetBandBottom &&
    //    indicatorPosition <= targetBandBottom + targetBandHeight);
    //bool excellentRelease = (gameLogic.getMissChance(gameLogic.lastDifference) == 0);    

    return Padding(
      padding: const EdgeInsets.symmetric(),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The shooting bar background
          SizedBox(
            width: barWidth,
            height: barHeight,
          ),

          // The target band (fixed position)
          Positioned(
            bottom: targetBandBottom,
            child: Container(
              width: barWidth,
              height: targetBandHeight,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),

          // The moving indicator
          if (gameLogic.isHolding)
            Positioned(
              bottom: 10 +
                  indicatorPosition -
                  targetBandHeight / 2, // Center the indicator
              child: Container(
                  width: barWidth,
                  height: targetBandHeight * 0.8,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 221, 221, 221),
                    border: Border.all(
                      color:
                          const Color.fromARGB(255, 0, 0, 0).withOpacity(0.8),
                      width: 1,
                    ),
                  )),
            ),
        ],
      ),
    );
  }

  Widget buildShotIndicator() {
    List<String> labels = [
      "Rack 1",
      "Rack 2",
      "Deep Zone",
      "Rack 3",
      "Deep Zone",
      "Rack 4",
      "Rack 5"
    ];

    return Positioned(
      bottom: 10,
      right: 10,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 71, 71, 71).withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(7, (row) {
            int circleCount = (row == 2 || row == 4) ? 1 : 5;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 70, // Adjust label width
                  child: Text(
                    labels[row],
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                SizedBox(width: 5),
                Row(
                  children: List.generate(circleCount, (col) {
                    bool shotMade = row < gameLogic.shotProgress.length &&
                        col < gameLogic.shotProgress[row].length &&
                        gameLogic.shotProgress[row][col];

                    Color fillColor = Colors.transparent;
                    if (shotMade) {
                      fillColor =
                          (row == 2 || row == 4) ? Colors.amber : Colors.green;
                    }

                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 1), // Better spacing
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fillColor,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// Add this widget to your file
class DigitalNumber extends StatelessWidget {
  final int number;
  final double height;
  final double width;
  final Color color;
  final bool isWarning;

  const DigitalNumber({
    Key? key,
    required this.number,
    this.height = 30,
    this.width = 16,
    this.color = Colors.red,
    this.isWarning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: DigitalNumberPainter(
        number: number,
        color: color,
        glowIntensity: isWarning ? 0.9 : 0.7, // Increased glow intensity
      ),
    );
  }
}

class DigitalNumberPainter extends CustomPainter {
  final int number;
  final Color color;
  final double glowIntensity;

  DigitalNumberPainter({
    required this.number,
    required this.color,
    this.glowIntensity = 0.7, // Default higher glow
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double segmentWidth = size.width * 0.15;
    final double segmentLength = size.width * 0.8;
    final double gap = size.width * 0.08;

    final Paint segmentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Enhanced glow with multiple layers for more realistic LED effect
    final Paint strongGlowPaint = Paint()
      ..color = color.withOpacity(glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0);

    final Paint softGlowPaint = Paint()
      ..color = color.withOpacity(glowIntensity * 0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0);

    // Draw each segment based on the digit
    final segments = _getActiveSegments(number);

    // Positions for each segment (a-g)
    // a: top horizontal
    if (segments.contains('a')) {
      _drawHorizontalSegment(
          canvas, Offset(gap, 0), segmentLength, segmentWidth, segmentPaint);
      _drawHorizontalSegment(
          canvas, Offset(gap, 0), segmentLength, segmentWidth, strongGlowPaint);
      _drawHorizontalSegment(
          canvas, Offset(gap, 0), segmentLength, segmentWidth, softGlowPaint);
    }

    // b: top-right vertical
    if (segments.contains('b')) {
      _drawVerticalSegment(canvas, Offset(gap + segmentLength, gap),
          size.height * 0.42, segmentWidth, segmentPaint);
      _drawVerticalSegment(canvas, Offset(gap + segmentLength, gap),
          size.height * 0.42, segmentWidth, strongGlowPaint);
      _drawVerticalSegment(canvas, Offset(gap + segmentLength, gap),
          size.height * 0.42, segmentWidth, softGlowPaint);
    }

    // c: bottom-right vertical
    if (segments.contains('c')) {
      _drawVerticalSegment(
          canvas,
          Offset(gap + segmentLength, size.height * 0.5 + gap),
          size.height * 0.42,
          segmentWidth,
          segmentPaint);
      _drawVerticalSegment(
          canvas,
          Offset(gap + segmentLength, size.height * 0.5 + gap),
          size.height * 0.42,
          segmentWidth,
          strongGlowPaint);
      _drawVerticalSegment(
          canvas,
          Offset(gap + segmentLength, size.height * 0.5 + gap),
          size.height * 0.42,
          segmentWidth,
          softGlowPaint);
    }

    // d: bottom horizontal
    if (segments.contains('d')) {
      _drawHorizontalSegment(canvas, Offset(gap, size.height - segmentWidth),
          segmentLength, segmentWidth, segmentPaint);
      _drawHorizontalSegment(canvas, Offset(gap, size.height - segmentWidth),
          segmentLength, segmentWidth, strongGlowPaint);
      _drawHorizontalSegment(canvas, Offset(gap, size.height - segmentWidth),
          segmentLength, segmentWidth, softGlowPaint);
    }

    // e: bottom-left vertical
    if (segments.contains('e')) {
      _drawVerticalSegment(canvas, Offset(0, size.height * 0.5 + gap),
          size.height * 0.42, segmentWidth, segmentPaint);
      _drawVerticalSegment(canvas, Offset(0, size.height * 0.5 + gap),
          size.height * 0.42, segmentWidth, strongGlowPaint);
      _drawVerticalSegment(canvas, Offset(0, size.height * 0.5 + gap),
          size.height * 0.42, segmentWidth, softGlowPaint);
    }

    // f: top-left vertical
    if (segments.contains('f')) {
      _drawVerticalSegment(canvas, Offset(0, gap), size.height * 0.42,
          segmentWidth, segmentPaint);
      _drawVerticalSegment(canvas, Offset(0, gap), size.height * 0.42,
          segmentWidth, strongGlowPaint);
      _drawVerticalSegment(canvas, Offset(0, gap), size.height * 0.42,
          segmentWidth, softGlowPaint);
    }

    // g: middle horizontal
    if (segments.contains('g')) {
      _drawHorizontalSegment(
          canvas,
          Offset(gap, size.height * 0.5 - segmentWidth / 2),
          segmentLength,
          segmentWidth,
          segmentPaint);
      _drawHorizontalSegment(
          canvas,
          Offset(gap, size.height * 0.5 - segmentWidth / 2),
          segmentLength,
          segmentWidth,
          strongGlowPaint);
      _drawHorizontalSegment(
          canvas,
          Offset(gap, size.height * 0.5 - segmentWidth / 2),
          segmentLength,
          segmentWidth,
          softGlowPaint);
    }
  }

  void _drawHorizontalSegment(Canvas canvas, Offset position, double length,
      double width, Paint paint) {
    final rect = Rect.fromLTWH(position.dx, position.dy, length, width);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(width / 2));
    canvas.drawRRect(rrect, paint);
  }

  void _drawVerticalSegment(Canvas canvas, Offset position, double length,
      double width, Paint paint) {
    final rect = Rect.fromLTWH(position.dx, position.dy, width, length);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(width / 2));
    canvas.drawRRect(rrect, paint);
  }

  List<String> _getActiveSegments(int digit) {
    // Segments a through g that should be lit for each digit
    switch (digit) {
      case 0:
        return ['a', 'b', 'c', 'd', 'e', 'f'];
      case 1:
        return ['b', 'c'];
      case 2:
        return ['a', 'b', 'g', 'e', 'd'];
      case 3:
        return ['a', 'b', 'g', 'c', 'd'];
      case 4:
        return ['f', 'g', 'b', 'c'];
      case 5:
        return ['a', 'f', 'g', 'c', 'd'];
      case 6:
        return ['a', 'f', 'g', 'c', 'd', 'e'];
      case 7:
        return ['a', 'b', 'c'];
      case 8:
        return ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
      case 9:
        return ['a', 'b', 'c', 'd', 'f', 'g'];
      default:
        return [];
    }
  }

  @override
  bool shouldRepaint(DigitalNumberPainter oldDelegate) {
    return oldDelegate.number != number ||
        oldDelegate.color != color ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

class ShotClockWidget extends StatelessWidget {
  final int timeLeft;
  final bool isWarning;

  const ShotClockWidget({
    Key? key,
    required this.timeLeft,
    this.isWarning = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tens = (timeLeft ~/ 10) % 10;
    final ones = timeLeft % 10;
    final Color digitColor =
        isWarning ? Colors.yellow.shade500 : Colors.yellow.shade600;

    return Container(
      width: 100,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.white,
          width: 3.0,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: isWarning
                ? Colors.red.withOpacity(0.8)
                : Colors.white.withOpacity(0.3),
            blurRadius: isWarning ? 12 : 6,
            spreadRadius: isWarning ? 3 : 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Scratched/worn effect overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.15)
                    ],
                    stops: [0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Background shadow for realism
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 3,
                  spreadRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),

          // Digital display
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DigitalNumber(
                  number: tens,
                  color: digitColor,
                  isWarning: isWarning,
                ),
                SizedBox(width: 10),
                DigitalNumber(
                  number: ones,
                  color: digitColor,
                  isWarning: isWarning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// For a pulsing effect when time is running low
class PulsingShotClock extends StatefulWidget {
  final int timeLeft;

  const PulsingShotClock({
    Key? key,
    required this.timeLeft,
  }) : super(key: key);

  @override
  _PulsingShotClockState createState() => _PulsingShotClockState();
}

class _PulsingShotClockState extends State<PulsingShotClock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isWarning = widget.timeLeft <= 10;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: isWarning ? _animation.value : 1.0,
          child: ShotClockWidget(
            timeLeft: widget.timeLeft,
            isWarning: isWarning,
          ),
        );
      },
    );
  }
}
