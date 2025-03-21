import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Container(
          width: 360, // Mobile width (e.g., Galaxy S20)
          height: 640, // Mobile height
          color: Colors.black,
          child: BasketballGame(),
        ),
      ),
    ),
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
    Future.delayed(Duration(seconds: 3), () {
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: null, // Remove the app bar
      body: SafeArea(
        child: showIntro
            ? Center(
                child: Text(
                  "Money Ball", 
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    color: Colors.orange
                  )
                ),
              )
            : inGame
                ? GestureDetector(
                    onTapDown: (_) => startHolding(),
                    onTapUp: (_) => releaseShot(),
                    child: Container(
                      color: Colors.transparent, // Make container transparent
                      width: double.infinity,
                      height: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          
                          Text("Time Left: $timeLeft", 
                            style: TextStyle(fontSize: 24, color: Colors.white)),
                          Text("Score: $score", 
                            style: TextStyle(fontSize: 24, color: Colors.white)),
                          Text("Shots Taken: $shotsTaken / $maxShots", 
                            style: TextStyle(fontSize: 24, color: Colors.white)),
                          Text("Held Time: ${heldTime.toStringAsFixed(1)}s", 
                            style: TextStyle(fontSize: 24, color: Colors.white)),
                          Text(
                                  "Optimal Time: ${optimalTime.toStringAsFixed(2)}s",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Courier',
                                    fontSize: 12,
                                  ),
                                ),
                          Text("Difference: ${(heldTime - optimalTime).abs().toStringAsFixed(2)}s",
                                style: TextStyle(
                                  color: (heldTime - optimalTime).abs() < 0.2 
                                    ? Colors.green 
                                    : Colors.red,
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                )),
                          SizedBox(height: 50),
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
                              fontSize: 32, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            )
                          ),
                          Text(
                            "Final Score: $score", 
                            style: TextStyle(fontSize: 24, color: Colors.white)
                          ),
                        ],
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: Text("Play", style: TextStyle(color: Colors.white)),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showIntro = false;
                              inGame = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: Text("Quit", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}