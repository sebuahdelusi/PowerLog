import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:powerlog/utils/timezone_converter.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileCard(),
            const SizedBox(height: 20),
            _TimezoneSection(),
          ],
        ),
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

class _ProfileCard extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003545), Color(0xFF001A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              color: AppColors.surfaceLight,
            ),
            child: const Icon(Icons.person, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Obx(() => Text(
                controller.username.value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )),
          const SizedBox(height: 4),
          const Text(
            'PowerLog User',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Timezone section ──────────────────────────────────────────────────────────

class _TimezoneSection extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'World Clock',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          // Rebuild every tick
          controller.currentTime.value; // subscribe
          return Column(
            children: controller.timezones
                .map((tz) => _TzCard(tz: tz))
                .toList(),
          );
        }),
      ],
    );
  }
}

// ── Single timezone card ──────────────────────────────────────────────────────

class _TzCard extends GetView<ProfileController> {
  final TzInfo tz;
  const _TzCard({required this.tz});

  static const _colors = {
    'WIB': AppColors.primary,
    'WITA': AppColors.accent,
    'WIT': AppColors.info,
    'London': AppColors.secondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[tz.code] ?? AppColors.primary;
    final time = controller.timeFor(tz);
    final date = controller.dateFor(tz);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tz.code,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  tz.label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
