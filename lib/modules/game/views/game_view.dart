import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/game_controller.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fix the Circuit ⚡'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() => IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                onPressed: controller.canUseHint ? controller.useHint : null,
                tooltip: controller.canUseHint ? 'Hint' : 'No hints left',
              )),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: controller.resetGame,
            tooltip: 'Shuffle',
          ),
        ],
      ),
      body: Column(
        children: [
          _Instructions(),
          _DifficultyRow(),
          _StatsRow(),
          const Spacer(),
          _GameBoard(),
          const Spacer(),
          _LegendRow(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Instructions ──────────────────────────────────────────────────────────────

class _Instructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tap tiles to rotate them. Use hints if stuck. Shuffle to start a new puzzle.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Difficulty row ─────────────────────────────────────────────────────────

class _DifficultyRow extends GetView<GameController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            const Text('Difficulty',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            _DiffChip(
              label: 'Easy',
              selected: controller.difficulty.value == GameDifficulty.easy,
              onTap: () => controller.setDifficulty(GameDifficulty.easy),
            ),
            const SizedBox(width: 6),
            _DiffChip(
              label: 'Medium',
              selected: controller.difficulty.value == GameDifficulty.medium,
              onTap: () => controller.setDifficulty(GameDifficulty.medium),
            ),
            const SizedBox(width: 6),
            _DiffChip(
              label: 'Hard',
              selected: controller.difficulty.value == GameDifficulty.hard,
              onTap: () => controller.setDifficulty(GameDifficulty.hard),
            ),
            const Spacer(),
            Text(
              'Lv ${controller.levelIndex.value + 1}/${controller.totalLevels}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _DiffChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DiffChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends GetView<GameController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final limit = controller.timeLimitSeconds;
      final elapsed = controller.elapsedSeconds.value;
      final remaining = (limit - elapsed).clamp(0, limit);
      final time = limit > 0
          ? '${_formatTime(remaining)} / ${_formatTime(limit)}'
          : _formatTime(elapsed);
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatItem(
              label: 'Level',
              value: '${controller.levelIndex.value + 1}/${controller.totalLevels}',
            ),
            _StatItem(label: 'Moves', value: '${controller.moves.value}'),
            _StatItem(label: 'Time', value: time),
            _StatItem(
              label: 'Hints',
              value: '${controller.hintsUsed.value}/${controller.hintLimit}',
            ),
          ],
        ),
      );
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}

// ── Game board ────────────────────────────────────────────────────────────────

class _GameBoard extends GetView<GameController> {
  // side indicators: 40px each; gaps: 4+4=8px; outer padding: 32*2=64px
  static const _indicatorW = 40.0;
  static const _gap = 4.0;
  static const _outerPadding = 32.0;
  static const _tileGap = 6.0; // margin all:3 → 6px per tile

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.version.value; // subscribe for rebuilds
      final powered = controller.poweredCells;

      return LayoutBuilder(builder: (context, constraints) {
        // Available width for the 3 tile columns
        final availW = constraints.maxWidth
            - _outerPadding * 2
            - _indicatorW * 2
            - _gap * 2;
        // Each tile occupies tileSize + tileGap pixels
        final tileSize = ((availW / 3) - _tileGap).clamp(40.0, 88.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _outerPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SourceIndicator(powered: powered.contains('1,0'), tileSize: tileSize),
              const SizedBox(width: _gap),

              // 3×3 grid
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (r) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (c) {
                    final tile = controller.grid[r][c];
                    final isPowered = powered.contains('$r,$c');
                    return _TileCell(
                      tile: tile,
                      isPowered: isPowered,
                      tileSize: tileSize,
                      onTap: () => controller.rotateTile(r, c),
                    );
                  }),
                )),
              ),

              const SizedBox(width: _gap),
              _BulbIndicator(powered: controller.isWon.value, tileSize: tileSize),
            ],
          ),
        );
      });
    });
  }
}

// ── Source (left) indicator ────────────────────────────────────────────────────

class _SourceIndicator extends StatelessWidget {
  final bool powered;
  final double tileSize;
  const _SourceIndicator({required this.powered, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    final h = tileSize + 6; // match tile height including margin
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: h), // align with row 1
        Container(
          width: 40,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            border: Border.all(
              color: powered ? AppColors.primary : AppColors.surfaceLight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt,
                  color: powered ? AppColors.primary : AppColors.textSecondary,
                  size: 22),
              const SizedBox(height: 2),
              Text('PWR',
                  style: TextStyle(
                    color: powered ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  )),
            ],
          ),
        ),
        SizedBox(height: h),
      ],
    );
  }
}

// ── Bulb (right) indicator ─────────────────────────────────────────────────────

class _BulbIndicator extends StatelessWidget {
  final bool powered;
  final double tileSize;
  const _BulbIndicator({required this.powered, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    final h = tileSize + 6;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 40,
          height: h,
          decoration: BoxDecoration(
            color: powered
                ? AppColors.secondary.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(
              color: powered ? AppColors.secondary : AppColors.surfaceLight,
            ),
            boxShadow: powered
                ? [BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                powered ? '💡' : '🔌',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(powered ? 'ON!' : 'OFF',
                  style: TextStyle(
                    color: powered ? AppColors.secondary : AppColors.textSecondary,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
        SizedBox(height: h),
      ],
    );
  }
}

// ── Individual tile cell ───────────────────────────────────────────────────────

class _TileCell extends StatelessWidget {
  final WireTile tile;
  final bool isPowered;
  final double tileSize;
  final VoidCallback onTap;

  const _TileCell({
    required this.tile,
    required this.isPowered,
    required this.tileSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: tileSize,
        height: tileSize,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isPowered
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPowered
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.surfaceLight,
            width: isPowered ? 1.5 : 1,
          ),
        ),
        child: CustomPaint(
          painter: _WirePainter(
            connections: tile.connections,
            powered: isPowered,
          ),
        ),
      ),
    );
  }
}

// ── Wire painter ──────────────────────────────────────────────────────────────

class _WirePainter extends CustomPainter {
  final Set<int> connections; // 0=N, 1=E, 2=S, 3=W
  final bool powered;

  const _WirePainter({required this.connections, required this.powered});

  static const _poweredColor = AppColors.primary;
  static const _idleColor = Color(0xFF3D5568);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);

    final wirePaint = Paint()
      ..color = powered ? _poweredColor : _idleColor
      ..strokeWidth = powered ? 7 : 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw wire segments from center to each connected edge
    for (final dir in connections) {
      final end = switch (dir) {
        0 => Offset(cx, 0),           // North
        1 => Offset(size.width, cy),  // East
        2 => Offset(cx, size.height), // South
        3 => Offset(0, cy),           // West
        _ => center,
      };
      canvas.drawLine(center, end, wirePaint);
    }

    // Center node
    final nodePaint = Paint()
      ..color = powered ? _poweredColor : _idleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, powered ? 7 : 5, nodePaint);
  }

  @override
  bool shouldRepaint(_WirePainter old) =>
      old.powered != powered || old.connections.toString() != connections.toString();
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: AppColors.primary,
          label: 'Powered',
          icon: Icons.bolt,
        ),
        const SizedBox(width: 24),
        _LegendItem(
          color: const Color(0xFF3D5568),
          label: 'Inactive',
          icon: Icons.remove,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;
  const _LegendItem({required this.color, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
