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
      startGameTimer(); // Start the timer when player begins their first shot
    }
    
    setState(() {
      isHolding = true;
      heldTime = 0.0;
    });
    
    holdTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        heldTime += 0.1;
        
        // Auto-release after 3 seconds of holding
        if (heldTime >= 2.5) {
          timer.cancel(); // Cancel the timer first to prevent further updates
          releaseShot(); // Call the release function
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

    // Cap the miss chance at 1.0 (100%) for differences > 0.3
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
                            ),
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