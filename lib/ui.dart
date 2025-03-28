import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math'; // For pow() function
import 'game_logic.dart';

class BasketballGame extends StatefulWidget {
  @override
  _BasketballGameState createState() => _BasketballGameState();
}

class _BasketballGameState extends State<BasketballGame> {
  late GameLogic gameLogic;

  @override
  void initState() {
    super.initState();
    gameLogic = GameLogic();
    gameLogic.initializeGame();

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        gameLogic.showIntro = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: null, // Remove the app bar
      body: Stack(
        children: [
          SafeArea(
            child: gameLogic.showIntro
                ? Center(
                    child: Text(
                      "Money Ball",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : gameLogic.inGame
                    ? GestureDetector(
                        onTapDown: (_) => gameLogic.startHolding(
                            () => setState(() {}),
                            () => gameLogic
                                .startGameTimer(() => setState(() {}))),
                        onTapUp: (_) {
                          if (gameLogic.isHolding) {
                            gameLogic.releaseShot(() => setState(() {}));
                          }
                        },
                        child: Container(
                          color:
                              Colors.transparent, // Make container transparent
                          width: double.infinity,
                          height: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Time Left: ${gameLogic.timeLeft}",
                                  style: TextStyle(
                                      fontSize: 24, color: Colors.white)),
                              Text("Score: ${gameLogic.score}",
                                  style: TextStyle(
                                      fontSize: 24, color: Colors.white)),
                              Text(
                                  "Shots Taken: ${gameLogic.shotsTaken} / ${gameLogic.totalShots}",
                                  style: TextStyle(
                                      fontSize: 24, color: Colors.white)),
                              Text(
                                  "Held Time: ${gameLogic.heldTime.toStringAsFixed(1)}s",
                                  style: TextStyle(
                                      fontSize: 24, color: Colors.white)),
                              // Add the new shooting bar widget here
                              buildShootingBar(),
                              Text(
                                "Optimal Time: ${gameLogic.optimalTime.toStringAsFixed(2)}s",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "Difference: ${(gameLogic.heldTime - gameLogic.optimalTime).abs().toStringAsFixed(2)}s",
                                style: TextStyle(
                                  color: (gameLogic.heldTime -
                                                  gameLogic.optimalTime)
                                              .abs() <
                                          0.2
                                      ? Colors.green
                                      : Colors.red,
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 50),
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
                                "Game Over!",
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
                              onPressed: () =>
                                  setState(() => gameLogic.startGame()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: Text("Ready",
                                  style: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      ),
          ),
          if (gameLogic.inGame || (gameLogic.shotsTaken > 0))
            buildShotIndicator(), // Add the shooting progress indicator
        ],
      ),
    );
  }

  // Widget to display the shooting bar
  Widget buildShootingBar() {
    // Define the time range for the bar (0 to 1.85 seconds)
    const double maxHoldTime =
        1.85; // Maximum hold time for scaling (top of the bar)
    const double barHeight = 200.0; // Height of the shooting bar
    const double barWidth = 30.0; // Width of the shooting bar

    // Fix the green band at 1.15–1.55 seconds
    const double minOptimalTime = 1.15; // Lower bound of green band
    const double maxOptimalTime = 1.55; // Upper bound of green band

    // Calculate the position of the green band (fixed position)
    double optimalBandBottom = (minOptimalTime / maxHoldTime) * barHeight;
    double optimalBandTop = (maxOptimalTime / maxHoldTime) * barHeight;
    double optimalBandHeight = optimalBandTop - optimalBandBottom;

    // Ensure the green band stays within the bar
    optimalBandBottom = optimalBandBottom.clamp(0, barHeight);
    optimalBandTop = optimalBandTop.clamp(0, barHeight);
    optimalBandHeight =
        (optimalBandTop - optimalBandBottom).clamp(0, barHeight);

    // Calculate the position of the moving indicator
    // Use a power function: position = k * (heldTime)^n
    double heldTime = gameLogic.heldTime
        .clamp(0, maxHoldTime); // Clamp held time to the range
    const double n = 2.0; // Exponent for acceleration (quadratic)

    // The center of the green band in seconds is (1.15 + 1.55) / 2 = 1.35
    const double greenBandCenterTime = (minOptimalTime + maxOptimalTime) / 2;
    // The center of the green band in pixels
    double greenBandCenterPosition =
        (greenBandCenterTime / maxHoldTime) * barHeight;

    // Calculate k so that at heldTime = gameLogic.optimalTime, the position is the center of the green band
    double k = greenBandCenterPosition / pow(gameLogic.optimalTime, n);
    double indicatorPosition = k * pow(heldTime, n);
    indicatorPosition =
        indicatorPosition.clamp(0, barHeight); // Ensure it stays within the bar

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The shooting bar (background)
          Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          // The green band (fixed position)
          Positioned(
            bottom: optimalBandBottom,
            child: Container(
              width: barWidth,
              height: optimalBandHeight,
              color: Colors.green.withOpacity(0.5),
            ),
          ),
          // The moving indicator
          if (gameLogic.isHolding) // Only show the indicator while holding
            Positioned(
              bottom: indicatorPosition,
              child: Container(
                width: barWidth,
                height: 5,
                color: (indicatorPosition >= optimalBandBottom &&
                        indicatorPosition <= optimalBandTop)
                    ? Colors
                        .green // Change color to green when in the optimal range
                    : Colors.white,
              ),
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
    );
  }
}
