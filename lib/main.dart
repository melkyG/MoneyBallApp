import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BasketballGame(),
  ));
}

class BasketballGame extends StatefulWidget {
  @override
  _BasketballGameState createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame> {
  int score = 0;
  int shotsTaken = 0;
  int maxShots = 25;
  double heldTime = 0.0;
  double optimalTime = 1.5;
  bool isHolding = false;
  Timer? holdTimer;
  Timer? gameTimer;
  int timeLeft = 60;
  bool showIntro = true;
  bool inGame = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        showIntro = false;
      });
    });
  }

  void startGame() {
    setState(() {
      inGame = true;
      score = 0;
      shotsTaken = 0;
      timeLeft = 60;
      resetOptimalTime();
    });
  }

  void endGame() {
    setState(() {
      inGame = false;
    });
  }

  void startGameTimer() {
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
          endGame();
        }
      });
    });
  }

  void resetOptimalTime() {
    setState(() {
      optimalTime = Random().nextDouble() + 1.0;
    });
  }

  void startHolding() {
    if (shotsTaken == 0 && inGame) {
      startGameTimer();
    }

    setState(() {
      isHolding = true;
      heldTime = 0.0;
    });

    holdTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        heldTime += 0.1;
        if (heldTime >= 2.5) {
          timer.cancel();
          releaseShot();
        }
      });
    });
  }

  void releaseShot() {
    if (holdTimer != null) {
      holdTimer!.cancel();
    }
    setState(() {
      isHolding = false;
      shotsTaken++;
    });

    double difference = (heldTime - optimalTime).abs();
    double missChance;

    difference = (difference * 10).round() / 10;

    if (difference <= 0.1) {
      missChance = 0;
    } else {
      missChance = (difference - 0.1) / 0.2;
    }

    if (missChance > 1.0) {
      missChance = 1.0;
    }

    if (Random().nextDouble() > missChance) {
      setState(() {
        score += 2;
      });
    }

    if (shotsTaken < maxShots) {
      resetOptimalTime();
    } else {
      gameTimer?.cancel();
      endGame();
    }
  }

  void open2DCourt() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BasketballCourt2D()),
    );
  }

  @override
  void dispose() {
    holdTimer?.cancel();
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double textSize = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: showIntro
            ? Center(
                child: Text(
                  "Money Ball",
                  style: TextStyle(
                    fontSize: textSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              )
            : inGame
                ? GestureDetector(
                    onTapDown: (_) => startHolding(),
                    onTapUp: (_) {
                      if (isHolding) {
                        releaseShot();
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      width: double.infinity,
                      height: double.infinity,
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Time Left: $timeLeft",
                              style: TextStyle(
                                  fontSize: textSize, color: Colors.white)),
                          SizedBox(height: screenHeight * 0.01),
                          Text("Score: $score",
                              style: TextStyle(
                                  fontSize: textSize, color: Colors.white)),
                          SizedBox(height: screenHeight * 0.01),
                          Text("Shots Taken: $shotsTaken / $maxShots",
                              style: TextStyle(
                                  fontSize: textSize, color: Colors.white)),
                          SizedBox(height: screenHeight * 0.02),
                          Text("Held Time: ${heldTime.toStringAsFixed(1)}s",
                              style: TextStyle(
                                  fontSize: textSize * 0.8,
                                  color: Colors.white)),
                          Text(
                              "Optimal Time: ${optimalTime.toStringAsFixed(2)}s",
                              style: TextStyle(
                                  fontSize: textSize * 0.6,
                                  color: Colors.white)),
                          Text(
                              "Difference: ${(heldTime - optimalTime).abs().toStringAsFixed(2)}s",
                              style: TextStyle(
                                fontSize: textSize * 0.6,
                                color: (heldTime - optimalTime).abs() < 0.2
                                    ? Colors.green
                                    : Colors.red,
                              )),
                          ElevatedButton(
                            onPressed: open2DCourt,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: Text("View 2D Court",
                                style: TextStyle(
                                    fontSize: textSize * 0.8,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (shotsTaken == maxShots || timeLeft == 0) ...[
                          Text(
                            "Game Over!",
                            style: TextStyle(
                              fontSize: textSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text("Final Score: $score",
                              style: TextStyle(
                                  fontSize: textSize * 0.8,
                                  color: Colors.white)),
                        ],
                        SizedBox(height: screenHeight * 0.05),
                        ElevatedButton(
                          onPressed: startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                                horizontal: screenWidth * 0.15),
                          ),
                          child: Text("Play",
                              style: TextStyle(
                                  fontSize: textSize * 0.8,
                                  color: Colors.white)),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showIntro = false;
                              inGame = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.015,
                                horizontal: screenWidth * 0.12),
                          ),
                          child: Text("Quit",
                              style: TextStyle(
                                  fontSize: textSize * 0.8,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class BasketballCourt2D extends StatefulWidget {
  @override
  _BasketballCourt2DState createState() => _BasketballCourt2DState();
}

class _BasketballCourt2DState extends State<BasketballCourt2D>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double ballX = 0.0;
  double ballY = 0.0;
  double initialVelocityX = 0.0;
  double initialVelocityY = 0.0;
  bool isHolding = false;
  double holdTime = 0.0;
  Timer? holdTimer;
  bool isShooting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..addListener(() {
        if (isShooting) {
          setState(() {
            double t = _animation.value;
            const double gravity = -9.8;

            // Update position
            ballX = initialVelocityX * t * 200;
            ballY = (initialVelocityY * t + 0.5 * gravity * t * t) * 200;

            // Check collision with hoop - Adjusted for lower trajectory
            if (ballX >= 350 && ballX <= 370 && ballY >= 40 && ballY <= 60) {
              // Ball hits hoop, simulate bounce
              initialVelocityY =
                  -initialVelocityY * 0.6; // Reverse and reduce Y velocity
              initialVelocityX =
                  initialVelocityX * 0.8; // Slightly reduce X velocity
              _controller.reset();
              _controller.forward();
            }
            // Check collision with backboard
            else if (ballX >= 360 &&
                ballX <= 380 &&
                ballY >= 20 &&
                ballY <= 80) {
              // Ball hits backboard, bounce back
              initialVelocityX =
                  -initialVelocityX * 0.7; // Reverse and reduce X velocity
              initialVelocityY =
                  initialVelocityY * 0.8; // Slightly reduce Y velocity
              _controller.reset();
              _controller.forward();
            }
            // Ball falls off-screen or stops
            else if (ballY < -200 || ballX > 450 || ballX < -50) {
              _controller.stop();
              isShooting = false;
              resetBall();
            }
          });
        }
      });

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    resetBall();
  }

  void resetBall() {
    setState(() {
      ballX = 0.0;
      ballY = 0.0;
      initialVelocityX = 0.0;
      initialVelocityY = 0.0;
      isShooting = false;
    });
  }

  void startHolding() {
    setState(() {
      isHolding = true;
      holdTime = 0.0;
    });

    holdTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        holdTime += 0.1;
        if (holdTime >= 2.5) {
          timer.cancel();
          releaseShot();
        }
      });
    });
  }

  void releaseShot() {
    if (holdTimer != null) {
      holdTimer!.cancel();
    }
    setState(() {
      isHolding = false;
      isShooting = true;
      initialVelocityX = 3.5; // Fixed horizontal velocity to reach hoop
      initialVelocityY =
          holdTime * 3.0; // Fixed vertical velocity for perfect arc
      _controller.reset();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("2D Basketball Court")),
      body: GestureDetector(
        onTapDown: (_) => startHolding(),
        onTapUp: (_) {
          if (isHolding) {
            releaseShot();
          }
        },
        child: Stack(
          children: [
            CustomPaint(
              painter: CourtPainter(ballX, ballY),
              size: Size.infinite,
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Text(
                "Hold Time: ${holdTime.toStringAsFixed(1)}s",
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CourtPainter extends CustomPainter {
  final double ballX;
  final double ballY;

  CourtPainter(this.ballX, this.ballY);

  @override
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw backboard (trapezoid to the right of the hoop)
    paint.color = Colors.grey[300]!;
    paint.style = PaintingStyle.fill;
    final backboardPath = Path()
      ..moveTo(
          size.width - 100, size.height / 2 - 80) // Top left (right of hoop)
      ..lineTo(size.width - 20, size.height / 2 - 100) // Top right (angled)
      ..lineTo(size.width - 20, size.height / 2) // Bottom right
      ..lineTo(size.width - 100, size.height / 2 - 20) // Bottom left
      ..close();
    canvas.drawPath(backboardPath, paint);

    // Draw hoop (ellipse for 3D effect)
    paint.color = Colors.red;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(
        center:
            Offset(size.width - 80, size.height / 2 - 20), // Hoop moved left
        width: 40,
        height: 20,
      ),
      paint,
    );
    // Draw court background
    paint.color = Colors.orange[200]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw basketball
    paint.color = Colors.orange;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(50 + ballX, size.height - 100 - ballY), 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
