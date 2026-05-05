import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';

// ── Tile model ────────────────────────────────────────────────────────────────

enum TileType { straight, lBend }

enum GameDifficulty { easy, medium, hard }

class LevelConfig {
  final int id;
  final int scrambleMoves;
  final int hintLimit;
  final int timeLimitSeconds;
  final GameDifficulty difficulty;

  const LevelConfig({
    required this.id,
    required this.scrambleMoves,
    required this.hintLimit,
    required this.timeLimitSeconds,
    required this.difficulty,
  });
}

class WireTile {
  TileType type;
  int rotation; // 0-3, clockwise

  WireTile(this.type, this.rotation);

  // Base connections: straight={E(1),W(3)}, lBend={N(0),E(1)}
  // Rotation shifts each direction by +rotation mod 4
  Set<int> get connections {
    final base = type == TileType.straight ? {1, 3} : {0, 1};
    return base.map((d) => (d + rotation) % 4).toSet();
  }

  void rotate() => rotation = (rotation + 1) % 4;
}

// ── Controller ────────────────────────────────────────────────────────────────

class GameController extends GetxController {
  // Grid: [row][col]
  late List<List<WireTile>> grid;
  late List<List<int>> _solutionRots;
  late List<List<TileType>> _solutionTypes;
  late int gridSize;

  final version = 0.obs;       // incremented on each tap to trigger Obx rebuild
  final isWon = false.obs;
  final poweredCells = <String>{}.obs; // 'r,c' keys
  final moves = 0.obs;
  final elapsedSeconds = 0.obs;
  final hintsUsed = 0.obs;
  final difficulty = GameDifficulty.easy.obs;
  final levelIndex = 0.obs;
  final compassHeading = 0.0.obs;
  final targetHeading = 0.0.obs;
  final isCompassAvailable = false.obs;

  final _rand = Random();
  Timer? _timer;
  StreamSubscription<MagnetometerEvent>? _magSub;
  DateTime? _lastCompassWarn;
  static const double _compassTolerance = 20.0;

  static final Map<GameDifficulty, List<LevelConfig>> _levelsByDifficulty = {
    GameDifficulty.easy: List.generate(
      12,
      (i) => LevelConfig(
        id: i + 1,
        scrambleMoves: 6 + i,
        hintLimit: 3,
        timeLimitSeconds: 0,
        difficulty: GameDifficulty.easy,
      ),
    ),
    GameDifficulty.medium: List.generate(
      12,
      (i) => LevelConfig(
        id: i + 1,
        scrambleMoves: 10 + i * 2,
        hintLimit: 2,
        timeLimitSeconds: 180,
        difficulty: GameDifficulty.medium,
      ),
    ),
    GameDifficulty.hard: List.generate(
      12,
      (i) => LevelConfig(
        id: i + 1,
        scrambleMoves: 16 + i * 3,
        hintLimit: 1,
        timeLimitSeconds: 120,
        difficulty: GameDifficulty.hard,
      ),
    ),
  };

  // Dynamic path-based solution generated per level.
  @override
  void onInit() {
    super.onInit();
    _startNewGame();
    _startCompass();
  }

  @override
  void onClose() {
    _timer?.cancel();
    _magSub?.cancel();
    _magSub = null;
    super.onClose();
  }

  List<LevelConfig> get _levels => _levelsByDifficulty[difficulty.value]!;
  LevelConfig get currentLevel => _levels[levelIndex.value];
  int get totalLevels => _levels.length;
  int get hintLimit => currentLevel.hintLimit;
  int get timeLimitSeconds => currentLevel.timeLimitSeconds;
  bool get canUseHint => hintsUsed.value < hintLimit;

  String get difficultyLabel {
    return switch (difficulty.value) {
      GameDifficulty.easy => 'Easy',
      GameDifficulty.medium => 'Medium',
      GameDifficulty.hard => 'Hard',
    };
  }

  int get sourceRow => gridSize ~/ 2;
  int get sourceCol => 0;
  int get targetRow => gridSize ~/ 2;
  int get targetCol => gridSize - 1;

  bool get isCompassAligned {
    if (!isCompassAvailable.value) return true;
    final diff = (compassHeading.value - targetHeading.value).abs();
    final delta = diff > 180 ? 360 - diff : diff;
    return delta <= _compassTolerance;
  }

  void _buildGrid(LevelConfig level) {
    gridSize = _computeGridSize(level);
    final path = _generatePath(gridSize);

    _solutionTypes = List.generate(
      gridSize,
      (_) => List.generate(
          gridSize, (_) => _rand.nextBool() ? TileType.straight : TileType.lBend),
    );
    _solutionRots = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => _rand.nextInt(4)),
    );

    _applyPathToSolution(path);

    grid = List.generate(gridSize, (r) => List.generate(gridSize, (c) {
      final rot = _solutionRots[r][c];
      return WireTile(_solutionTypes[r][c], rot);
    }));

    final scrambleMoves = level.scrambleMoves + (gridSize * 2);
    _applyScramble(scrambleMoves);
    var guard = 0;
    while (_isPathConnected() && guard < 5) {
      grid[_rand.nextInt(gridSize)][_rand.nextInt(gridSize)].rotate();
      guard++;
    }
  }

  void _startNewGame() {
    _setTargetHeading(currentLevel);
    _buildGrid(currentLevel);
    moves.value = 0;
    hintsUsed.value = 0;
    elapsedSeconds.value = 0;
    isWon.value = false;
    poweredCells.clear();
    _startTimer();
    _checkConnected(showSuccess: false);
    version.value++;
  }

  void _startCompass() {
    if (_magSub != null) return;
    _magSub = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      _onMagnetometer,
      onError: (_) {
        isCompassAvailable.value = false;
      },
    );
  }

  void _onMagnetometer(MagnetometerEvent event) {
    final heading = atan2(event.y, event.x) * (180 / pi);
    var deg = heading;
    if (deg < 0) deg += 360;
    compassHeading.value = deg;
    isCompassAvailable.value = true;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void rotateTile(int r, int c) {
    if (isWon.value) return;
    if (!isCompassAligned) {
      _showCompassLock();
      return;
    }
    grid[r][c].rotate();
    moves.value++;
    _checkConnected();
    version.value++;
  }

  void resetGame() {
    _startNewGame();
  }

  void nextLevel() {
    if (levelIndex.value < totalLevels - 1) {
      levelIndex.value++;
    } else {
      levelIndex.value = 0;
      Get.snackbar('All Levels Complete', 'Restarting from level 1.');
    }
    _startNewGame();
  }

  void setDifficulty(GameDifficulty next) {
    if (difficulty.value == next) return;
    difficulty.value = next;
    levelIndex.value = 0;
    _startNewGame();
  }

  void useHint() {
    if (isWon.value) return;
    if (!canUseHint) {
      Get.snackbar('No Hints Left', 'You have used all hints for this level.');
      return;
    }
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c].rotation != _solutionRots[r][c]) {
          grid[r][c].rotation = _solutionRots[r][c];
          hintsUsed.value++;
          _checkConnected();
          version.value++;
          return;
        }
      }
    }
  }

  // ── BFS connectivity ──────────────────────────────────────────────────────
  // Source is at (row=mid, left side) — enters from West (dir=3).
  // Win: reach (row=mid, last col) and it has East (dir=1) connection.

  void _checkConnected({bool showSuccess = true}) {
    final powered = <String>{};
    var won = false;

    // Source must accept West connection
    if (!grid[sourceRow][sourceCol].connections.contains(3)) {
      poweredCells.clear();
      isWon.value = false;
      return;
    }

    final queue = Queue<List<int>>(); // [row, col, incomingDir]
    final visited = <String>{};

    void enqueue(int r, int c, int from) {
      final key = '$r,$c,$from';
      if (!visited.contains(key)) {
        visited.add(key);
        powered.add('$r,$c');
        queue.add([r, c, from]);
      }
    }

    enqueue(sourceRow, sourceCol, 3);

    while (queue.isNotEmpty) {
      final curr = queue.removeFirst();
      final r = curr[0], c = curr[1], from = curr[2];

      for (final dir in grid[r][c].connections) {
        if (dir == from) continue;

        // Win condition: exit East from target
        if (r == targetRow && c == targetCol && dir == 1) {
          won = true;
          continue;
        }

        final nr = r + _dr(dir);
        final nc = c + _dc(dir);
        if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) continue;

        final opposite = (dir + 2) % 4;
        if (!grid[nr][nc].connections.contains(opposite)) continue;

        enqueue(nr, nc, opposite);
      }
    }

    poweredCells
      ..clear()
      ..addAll(powered);

    final wasAlreadyWon = isWon.value;
    isWon.value = won;
    if (won && !wasAlreadyWon) {
      _timer?.cancel();
      if (showSuccess) {
        Future.delayed(const Duration(milliseconds: 400), _showSuccess);
      }
    } else if (!won && wasAlreadyWon) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isWon.value) {
        elapsedSeconds.value++;
        if (timeLimitSeconds > 0 && elapsedSeconds.value >= timeLimitSeconds) {
          _timer?.cancel();
          _showTimeUp();
        }
      }
    });
  }

  void _applyScramble(int moves) {
    for (int i = 0; i < moves; i++) {
      final r = _rand.nextInt(gridSize);
      final c = _rand.nextInt(gridSize);
      grid[r][c].rotate();
    }
  }

  int _computeGridSize(LevelConfig level) {
    final base = switch (difficulty.value) {
      GameDifficulty.easy => 4,
      GameDifficulty.medium => 5,
      GameDifficulty.hard => 6,
    };
    final bump = (level.id - 1) ~/ 4; // every 4 levels add size
    final size = base + bump;
    return size.clamp(4, 6);
  }

  List<List<int>> _generatePath(int size) {
    final start = [sourceRow, sourceCol];
    final target = [targetRow, targetCol];
    final minLen = size + (size ~/ 2);

    for (int attempt = 0; attempt < 80; attempt++) {
      final path = <List<int>>[start];
      final visited = <String>{'${start[0]},${start[1]}'};

      bool dfs(int r, int c) {
        if (r == target[0] && c == target[1]) {
          return path.length >= minLen;
        }

        final dirs = [0, 1, 2, 3]; // N,E,S,W
        dirs.shuffle(_rand);
        if (_rand.nextDouble() < 0.6) {
          dirs.sort((a, b) {
            final da = _manhattan(r + _dr(a), c + _dc(a), target[0], target[1]);
            final db = _manhattan(r + _dr(b), c + _dc(b), target[0], target[1]);
            return da.compareTo(db);
          });
        }

        for (final dir in dirs) {
          final nr = r + _dr(dir);
          final nc = c + _dc(dir);
          if (nr < 0 || nr >= size || nc < 0 || nc >= size) continue;
          final key = '$nr,$nc';
          if (visited.contains(key)) continue;
          visited.add(key);
          path.add([nr, nc]);
          if (dfs(nr, nc)) return true;
          path.removeLast();
          visited.remove(key);
        }
        return false;
      }

      if (dfs(start[0], start[1])) {
        return path;
      }
    }

    // Fallback: simple straight path
    final fallback = <List<int>>[];
    for (int c = 0; c < size; c++) {
      fallback.add([sourceRow, c]);
    }
    return fallback;
  }

  void _applyPathToSolution(List<List<int>> path) {
    for (int i = 0; i < path.length; i++) {
      final r = path[i][0];
      final c = path[i][1];
      final required = <int>{};

      if (i == 0) {
        required.add(3); // west from source
        final next = path[i + 1];
        required.add(_dirBetween(r, c, next[0], next[1]));
      } else if (i == path.length - 1) {
        required.add(1); // east to bulb
        final prev = path[i - 1];
        required.add(_dirBetween(r, c, prev[0], prev[1]));
      } else {
        final prev = path[i - 1];
        final next = path[i + 1];
        required.add(_dirBetween(r, c, prev[0], prev[1]));
        required.add(_dirBetween(r, c, next[0], next[1]));
      }

      final match = _matchTile(required);
      _solutionTypes[r][c] = match.$1;
      _solutionRots[r][c] = match.$2;
    }
  }

  (TileType, int) _matchTile(Set<int> required) {
    for (final type in [TileType.straight, TileType.lBend]) {
      for (int rot = 0; rot < 4; rot++) {
        if (_connectionsFor(type, rot).containsAll(required) &&
            _connectionsFor(type, rot).length == required.length) {
          return (type, rot);
        }
      }
    }
    return (TileType.straight, 0);
  }

  Set<int> _connectionsFor(TileType type, int rotation) {
    final base = type == TileType.straight ? {1, 3} : {0, 1};
    return base.map((d) => (d + rotation) % 4).toSet();
  }

  int _dirBetween(int r, int c, int nr, int nc) {
    if (nr == r - 1 && nc == c) return 0;
    if (nr == r && nc == c + 1) return 1;
    if (nr == r + 1 && nc == c) return 2;
    return 3;
  }

  int _dr(int dir) => [-1, 0, 1, 0][dir];
  int _dc(int dir) => [0, 1, 0, -1][dir];
  int _manhattan(int r, int c, int tr, int tc) => (r - tr).abs() + (c - tc).abs();

  bool _isPathConnected() {
    // quick check using BFS without side effects
    if (!grid[sourceRow][sourceCol].connections.contains(3)) return false;

    final queue = Queue<List<int>>();
    final visited = <String>{};
    queue.add([sourceRow, sourceCol, 3]);

    while (queue.isNotEmpty) {
      final curr = queue.removeFirst();
      final r = curr[0], c = curr[1], from = curr[2];
      final key = '$r,$c,$from';
      if (visited.contains(key)) continue;
      visited.add(key);

      for (final dir in grid[r][c].connections) {
        if (dir == from) continue;
        if (r == targetRow && c == targetCol && dir == 1) {
          return true;
        }
        final nr = r + _dr(dir);
        final nc = c + _dc(dir);
        if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) continue;
        final opposite = (dir + 2) % 4;
        if (!grid[nr][nc].connections.contains(opposite)) continue;
        queue.add([nr, nc, opposite]);
      }
    }
    return false;
  }

  void _setTargetHeading(LevelConfig level) {
    const targets = [0, 90, 180, 270];
    final difficultyIndex = difficulty.value.index;
    final index = (level.id + difficultyIndex) % targets.length;
    targetHeading.value = targets[index].toDouble();
  }

  void _showCompassLock() {
    final now = DateTime.now();
    if (_lastCompassWarn != null &&
        now.difference(_lastCompassWarn!) < const Duration(seconds: 2)) {
      return;
    }
    _lastCompassWarn = now;
    final target = targetHeading.value.toStringAsFixed(0);
    Get.snackbar(
      'Compass Lock',
      'Align phone to $target° to rotate tiles.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(12),
    );
  }

  void _showTimeUp() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏱️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Time Up!',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try the level again or change difficulty.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      resetGame();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00E5FF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Retry',
                        style: TextStyle(color: Color(0xFF00E5FF))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Exit',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showSuccess() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: const Text('💡', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Circuit Complete!',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You connected the power source to the lightbulb!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      resetGame();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00E5FF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Retry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF00E5FF)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      nextLevel();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Next Level',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B949E)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Exit',
                    style: TextStyle(color: Color(0xFF8B949E))),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
}
