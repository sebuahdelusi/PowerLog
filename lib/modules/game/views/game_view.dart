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
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: controller.resetGame,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          _Instructions(),
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
              'Tap tiles to rotate them. Connect the ⚡ source (left) to the 💡 bulb (right).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Game board ────────────────────────────────────────────────────────────────

class _GameBoard extends GetView<GameController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.version.value; // subscribe for rebuilds
      final powered = controller.poweredCells;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Source indicator
            _SourceIndicator(powered: powered.contains('1,0')),
            const SizedBox(width: 4),

            // 3x3 grid
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
                    onTap: () => controller.rotateTile(r, c),
                  );
                }),
              )),
            ),

            const SizedBox(width: 4),
            // Bulb indicator
            _BulbIndicator(powered: controller.isWon.value),
          ],
        ),
      );
    });
  }
}

// ── Source (left) indicator ────────────────────────────────────────────────────

class _SourceIndicator extends StatelessWidget {
  final bool powered;
  const _SourceIndicator({required this.powered});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 72), // align with row 1
        Container(
          width: 40,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            border: Border.all(
              color: powered
                  ? AppColors.primary
                  : AppColors.surfaceLight,
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
        const SizedBox(height: 72),
      ],
    );
  }
}

// ── Bulb (right) indicator ─────────────────────────────────────────────────────

class _BulbIndicator extends StatelessWidget {
  final bool powered;
  const _BulbIndicator({required this.powered});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 72),
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 40,
          height: 72,
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
        const SizedBox(height: 72),
      ],
    );
  }
}

// ── Individual tile cell ───────────────────────────────────────────────────────

class _TileCell extends StatelessWidget {
  final WireTile tile;
  final bool isPowered;
  final VoidCallback onTap;

  const _TileCell({
    required this.tile,
    required this.isPowered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        height: 72,
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
