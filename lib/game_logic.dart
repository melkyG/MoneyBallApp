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
  double maxHoldTime = 2.5;
  bool isHolding = false;
  Timer? holdTimer;
  Timer? gameTimer;

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
    inGame = false;
  }

  void startGameTimer(Function updateState) {
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        timeLeft--;
        updateState();
      } else {
        timer.cancel();
        endGame();
        updateState();
      }
    });
  }

  void resetOptimalTime() {
    optimalTime = Random().nextDouble() + 0.85;
  }

  void startHolding(Function updateState, Function startTimer) {
    if (shotsTaken == 0 && inGame) {
      startTimer(); // Start the timer when player begins their first shot
    }

    isHolding = true;
    heldTime = 0.0;

    holdTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      heldTime += 0.1;
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

    double difference = (heldTime - optimalTime).abs();
    double missChance = difference <= 0.1 ? 0 : (difference - 0.1) / 0.2;

    if (missChance > 1.0) {
      missChance = 1.0;
    }

    bool shotMade = Random().nextDouble() > missChance;
    int row = getShotRow(shotsTaken - 1);
    
    if (row < shotProgress.length) {
      shotProgress[row].add(shotMade);
    }
    if (shotMade) {
      score += getShotPoints(shotsTaken - 1);
    }

    if (shotsTaken < totalShots) {
      resetOptimalTime();
    } else {
      gameTimer?.cancel();
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
    if (shotIndex < 21) return 5;
    return 6;
  }

  int getShotPoints(int shotIndex) {
    if (shotIndex == 10 || shotIndex == 16) return 3; // Money Balls worth 3 points
    return (shotIndex % 5 == 4) ? 2 : 1; // Last ball in each rack worth 2, others worth 1
  }
}