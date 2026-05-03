import 'dart:collection';
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
  // Initial scramble offsets — verified: (1,0) rot=0 → {N,E}, has no W → not solved at start
  static const _scramble = [
    [2, 1, 1],
    [1, 1, 2],
    [1, 2, 2],
  ];

  @override
  void onInit() {
    super.onInit();
    _buildGrid();
  }

  void _buildGrid() {
    grid = List.generate(3, (r) => List.generate(3, (c) {
      final rot = (_solutionRots[r][c] + _scramble[r][c]) % 4;
      return WireTile(_solutionTypes[r][c], rot);
    }));
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void rotateTile(int r, int c) {
    if (isWon.value) return;
    grid[r][c].rotate();
    _checkConnected();
    version.value++;
  }

  void resetGame() {
    _buildGrid();
    isWon.value = false;
    poweredCells.clear();
    version.value++;
  }

  // ── BFS connectivity ──────────────────────────────────────────────────────
  // Source is at (row=1, left side) — enters (1,0) from West (dir=3).
  // Win: reach (1,2) and it has East (dir=1) connection.

  void _checkConnected() {
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
    isWon.value = won;
    if (won) Future.delayed(const Duration(milliseconds: 400), _showSuccess);
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
                    ),
                    child: const Text('Play Again',
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
