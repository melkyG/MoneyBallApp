import 'dart:async';
import 'dart:math';

class GameLogic {
  int score = 0;
  int shotsTaken = 0;
  int timeLeft = 60;
  bool showIntro = true;
  bool inGame = false;
  double heldTime = 0.0;
  double optimalTime = 1.5;
  double maxHoldTime = 1.8;
  bool isHolding = false;
  Timer? holdTimer;
  Timer? gameTimer;
  bool shotMade = false;
  double randomLow = 0.6;
  double randomHigh = 0.70;
  double totalDifference = 0;
  double lastDifference = 0.0;
  double lastDifferenceTrue = 0.0;
  double getMissChance(double difference) {
    if (difference < 0.015) return 0.0;
    if (difference < 0.04) return 0.55;
    if (difference < 0.07) return 0.7;
    if (difference < 0.08) return 0.9;
    return 1.0;
  }

  final int totalShots = 27; // 5 racks * 5 shots + 2 money balls
  List<int> shotValues = [];
  List<List<bool>> shotProgress = List.generate(7, (_) => []);
  List<List<bool?>> shotResults = List.generate(7, (_) => List.filled(5, null));

  void initializeGame() {
    _generateShotValues();
    showIntro = true;
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
    inGame = true;
    score = 0;
    shotsTaken = 0;
    timeLeft = 60;
    _generateShotValues();
    resetOptimalTime();
    shotProgress = List.generate(7, (_) => []);
    shotResults = List.generate(7, (_) => List.filled(5, null));
  }

  void endGame() {
    print("in endGame function");
    Future.delayed(Duration(milliseconds: 2400), () {
      
    inGame = false;}
    );
  }

  void startGameTimer(Function updateState) {
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        timeLeft--;
        updateState();
      } else {
        timer.cancel();
        print("ending game: times ran out");
        endGame();
        updateState();
      }
    });
  }

  void resetOptimalTime() {
  // Randomly decide whether to apply the multiplier (e.g., 30% chance)
  bool applyMultiplier = Random().nextDouble() < 0.65;
  
  double low = randomLow;
  double high = randomHigh;
  
  // If we decided to apply the multiplier, adjust the values
  if (applyMultiplier) {
    low *= 1.4;
    high *= 1.15;
  }
  
  // Calculate optimalTime using the potentially modified range
  optimalTime = low + Random().nextDouble() * (high - low);
}

  void startHolding(Function updateState, Function startTimer) {
    if (shotsTaken == 0 && inGame) {
      startTimer(); // Start the timer when player begins their first shot
    }

    isHolding = true;
    heldTime = 0.0;

    holdTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      heldTime += 0.01;
      updateState();

      // Auto-release after 3 seconds of holding
      if (heldTime >= maxHoldTime) {
        timer.cancel();
        releaseShot(updateState);
      }
    });
  }

  void releaseShot(Function updateState) {
    if (holdTimer != null) {
      holdTimer!.cancel();
    }

    shotsTaken++;
    isHolding = false;

    double differenceTrue = (heldTime - optimalTime);
    lastDifferenceTrue = differenceTrue;
    double difference = differenceTrue.abs();
    
    lastDifference = difference;
    //print("Computed Difference in releaseShot: ${difference.toStringAsFixed(3)}");
    totalDifference += difference; // Accumulate difference
    double averageDifference = totalDifference / shotsTaken; // Compute average

    double missChance = getMissChance(difference);

    if (missChance > 1.0) {
      shotMade = false;
    } else {
      shotMade = Random().nextDouble() > missChance;
    }

    int row = getShotRow(shotsTaken - 1);
    if (row < shotProgress.length) {
      shotProgress[row].add(shotMade);
    }
    

    // Print Table Header on First Shot
    if (shotsTaken == 1) {
      print("| Shot # | Difference | Avg Diff | Miss % | Result |");
      print("|--------|------------|----------|--------|--------|");
    }

    // Format Result
    String result = shotMade ? "Scored" : "Missed";

    // Print Data in Table Format
    print(
      "| ${shotsTaken.toString().padLeft(6)} | "
      "${difference.toStringAsFixed(3).padLeft(9)}  | "
      "${averageDifference.toStringAsFixed(3).padLeft(7)}  | "
      "${(missChance * 100).toStringAsFixed(0).padLeft(6)} | "
      "${result.padRight(7)}|"
    );

    // Update Score
    if (shotMade) {
      score += getShotPoints(shotsTaken - 1);
    }

    // Handle Game Progress
    if (shotsTaken < totalShots) {
      resetOptimalTime();
    } else {
      gameTimer?.cancel();
      print("ending game: shots ran out");
      endGame();
    }

    updateState();
}

  // Helper methods
  int getShotRow(int shotIndex) {
    // Order: Rack 1, Rack 2, Money Ball 1, Rack 3, Money Ball 2, Rack 4, Rack 5
    if (shotIndex < 5) return 0;
    if (shotIndex < 10) return 1;
    if (shotIndex == 10) return 2;
    if (shotIndex < 16) return 3;
    if (shotIndex == 16) return 4;
    if (shotIndex < 22) return 5;
    return 6;
  }

  int getShotPoints(int shotIndex) {
    if (shotIndex == 10 || shotIndex == 16) {return 3;}
    return (shotIndex % 5 == 4)
        ? 2
        : 1; // Last ball in each rack worth 2, others worth 1
  }
}