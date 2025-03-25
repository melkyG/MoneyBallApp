import 'package:flutter/material.dart';
import 'ui.dart';

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




/*
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
  int timeLeft = 60;
  bool showIntro = true;
  bool inGame = false;
  double heldTime = 0.0;
  double optimalTime = 1.5;
  double maxHoldTime = 2.5;
  bool isHolding = false;
  Timer? holdTimer;
  Timer? gameTimer;

  final int totalShots = 27; // 5 racks * 5 shots + 2 money balls
  List<int> shotValues = [];
  List<List<bool>> shotProgress = List.generate(7, (_) => []); //track shot success for shot progress indicator
  List<List<bool?>> shotResults = List.generate(7, (_) => List.filled(5, null));

  @override
  void initState() {
    super.initState();
    _generateShotValues();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        showIntro = false;
      });
    });
  }

  void _generateShotValues() {
    shotValues = [
      ...List.filled(4, 1), // First 4 shots in rack 1 (1 point each)
      2, // 5th shot in rack 1 (2 points)
      ...List.filled(4, 1),
      2,
      3, // Money Ball 1 (3 points)
      ...List.filled(4, 1),
      2,
      3, // Money Ball 2 (3 points)
      ...List.filled(4, 1),
      2,
      ...List.filled(4, 1),
      2
    ];
  }

  void startGame() {
    setState(() {
      holdTimer?.cancel();
      inGame = true;
      score = 0;
      shotsTaken = 0;
      timeLeft = 60;
      _generateShotValues();
      resetOptimalTime();
      shotProgress = List.generate(7, (_) => []);  // Reset shot indicators
      shotResults = List.generate(7, (_) => List.filled(5, null));
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
      optimalTime = Random().nextDouble() + 0.85;
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
        if (heldTime >= maxHoldTime) {
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
    double missChance = difference <= 0.1 ? 0 : (difference - 0.1) / 0.2;

    if (missChance > 1.0) {
      missChance = 1.0;
    }

    bool shotMade = Random().nextDouble() > missChance;
    int row = getShotRow(shotsTaken - 1);
    
    setState(() {
      if (row < shotProgress.length) {
        shotProgress[row].add(shotMade);
      }
      if (shotMade) {
        score += getShotPoints(shotsTaken - 1);
      }
    });

    if (shotsTaken < totalShots) {
      resetOptimalTime();
    } else {
      gameTimer?.cancel();
      endGame();
    }
  }

int getShotRow(int shotIndex) {
  // Order: Rack 1, Rack 2, Money Ball 1, Rack 3, Money Ball 2, Rack 4, Rack 5
  if (shotIndex < 5) return 0;
  if (shotIndex < 10) return 1;
  if (shotIndex == 10) return 2;
  if (shotIndex < 16) return 3;
  if (shotIndex == 16) return 4;
  if (shotIndex < 21) return 5;
  return 6;
}

int getShotPoints(int shotIndex) {
  if (shotIndex == 10 || shotIndex == 16) return 3; // Money Balls worth 3 points
  return (shotIndex % 5 == 4) ? 2 : 1; // Last ball in each rack worth 2, others worth 1
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: null, // Remove the app bar
      body: Stack(
        children: [
          SafeArea(
            child: showIntro
                ? Center(
                    child: Text(
                      "Money Ball", 
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold,
                        color: Colors.grey
                      )
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
                              Text("Shots Taken: $shotsTaken / $totalShots ", 
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
                            if (shotsTaken == totalShots  || timeLeft == 0) ...[
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
                                backgroundColor: Colors.green,
                              ),
                              child: Text("Ready", style: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
          ),
        if (inGame || (shotsTaken > 0)) (buildShotIndicator()), // Add the shooting progress indicator
        ],              
      ),
    );  
  }
  Widget buildShotIndicator() {
    List<String> labels = [
      "Rack 1", "Rack 2", "Deep Zone", "Rack 3", "Deep Zone", "Rack 4", "Rack 5"
    ];

    return Positioned(
      bottom: 10,
      left: 10,
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
                  bool shotMade = row < shotProgress.length &&
                                  col < shotProgress[row].length &&
                                  shotProgress[row][col];

                  Color fillColor = Colors.transparent;
                  if (shotMade) {
                    fillColor = (row == 2 || row == 4) ? Colors.amber : Colors.green;
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1), // Better spacing
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
    );
  }
}

*/