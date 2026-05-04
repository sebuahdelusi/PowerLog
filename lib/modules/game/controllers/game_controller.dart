import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ── Tile model ────────────────────────────────────────────────────────────────

enum TileType { straight, lBend }

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

  final version = 0.obs;       // incremented on each tap to trigger Obx rebuild
  final isWon = false.obs;
  final poweredCells = <String>{}.obs; // 'r,c' keys
  final moves = 0.obs;
  final elapsedSeconds = 0.obs;
  final hintsUsed = 0.obs;

  final _rand = Random();
  Timer? _timer;

  // ── Solution (correct rotations) ──────────────────────────────────────────
  // Path: source→(1,0)→(0,0)→(0,1)→(0,2)→(1,2)→bulb
  static const _solutionTypes = [
    [TileType.lBend,   TileType.straight, TileType.lBend],   // row 0
    [TileType.lBend,   TileType.straight, TileType.lBend],   // row 1
    [TileType.lBend,   TileType.straight, TileType.lBend],   // row 2
  ];
  static const _solutionRots = [
    [1, 0, 2], // row 0: {E,S}, {E,W}, {S,W}
    [3, 1, 0], // row 1: {W,N}, {N,S}, {N,E}
    [0, 0, 3], // row 2: {N,E}, {E,W}, {W,N}
  ];
  @override
  void onInit() {
    super.onInit();
    _startNewGame();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _buildGrid() {
    grid = List.generate(3, (r) => List.generate(3, (c) {
      final rot = _rand.nextInt(4);
      return WireTile(_solutionTypes[r][c], rot);
    }));

    // Ensure not solved at start by blocking the West connection on (1,0)
    while (grid[1][0].connections.contains(3)) {
      grid[1][0].rotate();
    }
  }

  void _startNewGame() {
    _buildGrid();
    moves.value = 0;
    hintsUsed.value = 0;
    elapsedSeconds.value = 0;
    isWon.value = false;
    poweredCells.clear();
    _startTimer();
    _checkConnected(showSuccess: false);
    version.value++;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void rotateTile(int r, int c) {
    if (isWon.value) return;
    grid[r][c].rotate();
    moves.value++;
    _checkConnected();
    version.value++;
  }

  void resetGame() {
    _startNewGame();
  }

  void useHint() {
    if (isWon.value) return;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
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
  // Source is at (row=1, left side) — enters (1,0) from West (dir=3).
  // Win: reach (1,2) and it has East (dir=1) connection.

  void _checkConnected({bool showSuccess = true}) {
    final powered = <String>{};
    var won = false;

    // (1,0) must accept West connection
    if (!grid[1][0].connections.contains(3)) {
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

    enqueue(1, 0, 3);

    while (queue.isNotEmpty) {
      final curr = queue.removeFirst();
      final r = curr[0], c = curr[1], from = curr[2];

      for (final dir in grid[r][c].connections) {
        if (dir == from) continue;

        // Win condition: exit East from (1,2)
        if (r == 1 && c == 2 && dir == 1) {
          won = true;
          continue;
        }

        final nr = r + [-1, 0, 1, 0][dir];
        final nc = c + [0, 1, 0, -1][dir];
        if (nr < 0 || nr > 2 || nc < 0 || nc > 2) continue;

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
      }
    });
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
                      'Play Again',
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
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
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
}
