import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/nearest_pln_controller.dart';

class NearestPlnView extends GetView<NearestPlnController> {
  const NearestPlnView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nearest PLN Office'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() => _buildBody()),
    );
  }

  Widget _buildBody() {
    return switch (controller.state.value) {
      PlnState.idle => const SizedBox.shrink(),
      PlnState.loading => _LoadingState(),
      PlnState.success => _SuccessState(),
      PlnState.error => _ErrorState(),
    };
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Getting your location…',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please allow location access when prompted.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Success ───────────────────────────────────────────────────────────────────

class _SuccessState extends GetView<NearestPlnController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // Real map card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Obx(() {
                final lat = controller.latitude.value;
                final lng = controller.longitude.value;
                final center = LatLng(lat, lng);
                return FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.powerlog',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 48,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Coordinates display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              children: [
                _CoordRow(
                  label: 'Latitude',
                  value:
                      controller.latitude.value.toStringAsFixed(6),
                  icon: Icons.north,
                ),
                const Divider(color: AppColors.surfaceLight, height: 20),
                _CoordRow(
                  label: 'Longitude',
                  value:
                      controller.longitude.value.toStringAsFixed(6),
                  icon: Icons.east,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap the button below to find the nearest PLN office in Google Maps.',
                    style:
                        TextStyle(color: AppColors.success, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Open Maps button
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: controller.openInMaps,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.map_outlined, size: 22),
              label: const Text(
                'Open in Google Maps',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextButton.icon(
            onPressed: controller.fetchLocationAndOpen,
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 16),
            label: const Text('Re-fetch location',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorState extends GetView<NearestPlnController> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.location_off, color: AppColors.error, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Unavailable',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                )),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: controller.fetchLocationAndOpen,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coordinate row ────────────────────────────────────────────────────────────

class _CoordRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _CoordRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()])),
      ],
    );
  }
}


