import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:powerlog/utils/timezone_converter.dart';
import 'package:powerlog/utils/currency_names.dart' as currency_names;
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
            _AchievementsSection(),
            const SizedBox(height: 20),
            _SettingsSection(),
            const SizedBox(height: 20),
            _CompassSection(),
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
          Obx(
            () => Text(
              controller.username.value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'PowerLog User',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: controller.isExporting.value
                          ? null
                          : controller.exportPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: controller.isExporting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf, size: 18),
                      label: Text(
                        controller.isExporting.value
                            ? 'Generating...'
                            : 'Export PDF',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: controller.isExportingCsv.value
                          ? null
                          : controller.exportCsv,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.7),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: controller.isExportingCsv.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: AppColors.secondary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.table_view, size: 18),
                      label: Text(
                        controller.isExportingCsv.value
                            ? 'Generating...'
                            : 'Export CSV',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Achievements section ──────────────────────────────────────────────────────

class _AchievementsSection extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.accent,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Eco-Achievements',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _buildBadge(
                  title: '7-Day Streak',
                  subtitle: 'Logged 7 days in a row',
                  icon: Icons.local_fire_department,
                  isUnlocked: controller.has7DayStreak.value,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(
                () => _buildBadge(
                  title: 'Eco Saver',
                  subtitle: 'Last log < 5 kWh',
                  icon: Icons.eco,
                  isUnlocked: controller.isEcoSaver.value,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Beautifully styled container for simulating scenarios to test achievements
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Achievement Simulator (Testing)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Simulate electricity usage logs to verify the badge unlocking mechanics immediately:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSimChip(
                      label: 'Eco Saver',
                      icon: Icons.eco,
                      color: Colors.greenAccent,
                      onTap: () => controller.seedMockLogs('eco_saver'),
                    ),
                    const SizedBox(width: 8),
                    _buildSimChip(
                      label: '7-Day Streak',
                      icon: Icons.local_fire_department,
                      color: Colors.orangeAccent,
                      onTap: () => controller.seedMockLogs('streak'),
                    ),
                    const SizedBox(width: 8),
                    _buildSimChip(
                      label: 'Heavy Log',
                      icon: Icons.bolt,
                      color: Colors.redAccent,
                      onTap: () => controller.seedMockLogs('heavy'),
                    ),
                    const SizedBox(width: 8),
                    _buildSimChip(
                      label: 'Reset',
                      icon: Icons.refresh,
                      color: AppColors.textSecondary,
                      onTap: () => controller.seedMockLogs('clear'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUnlocked,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? color.withValues(alpha: 0.4)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isUnlocked
                ? color
                : AppColors.textSecondary.withValues(alpha: 0.3),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isUnlocked
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(
                alpha: isUnlocked ? 0.8 : 0.4,
              ),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings section ────────────────────────────────────────────────────────────

class _SettingsSection extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                if (controller.isBiometricSupported.value) ...[
                  SwitchListTile(
                    value: controller.isBiometricEnabled.value,
                    onChanged: controller.toggleBiometric,
                    title: const Text(
                      'Biometric Login',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Use fingerprint/face to login after logout',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    secondary: const Icon(
                      Icons.fingerprint,
                      color: AppColors.primary,
                    ),
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                    activeThumbColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const Divider(color: AppColors.surfaceLight, height: 1),
                ],
                SwitchListTile(
                  value: controller.isNotificationEnabled.value,
                  onChanged: controller.toggleNotification,
                  title: const Text(
                    'Auto Reminder (Token-based)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    controller.autoReminderSubtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  secondary: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                  ),
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  activeThumbColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const Divider(color: AppColors.surfaceLight, height: 1),
                SwitchListTile(
                  value: controller.isCustomReminderEnabled.value,
                  onChanged: controller.toggleCustomReminder,
                  title: const Text(
                    'Custom Reminder',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Pick your own date and time',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  secondary: const Icon(
                    Icons.event_available,
                    color: AppColors.primary,
                  ),
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  activeThumbColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                if (controller.isCustomReminderEnabled.value) ...[
                  const Divider(color: AppColors.surfaceLight, height: 1),
                  ListTile(
                    onTap: () async {
                      final initial = controller.customReminderDateTime.value;
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: initial,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate == null) return;
                      if (!context.mounted) return;

                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(initial),
                      );
                      if (pickedTime == null) return;

                      final next = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      await controller.setCustomReminderDateTime(next);
                    },
                    title: const Text(
                      'Custom Reminder Time',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      controller.customReminderLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    leading: const Icon(
                      Icons.access_time,
                      color: AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ],
                const Divider(color: AppColors.surfaceLight, height: 1),
                ListTile(
                  onTap: () => _openCurrencyPicker(context),
                  title: const Text(
                    'Currency Preferences',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Obx(() {
                    if (controller.isCurrencyLoading.value) {
                      return const Text(
                        'Loading currencies...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      );
                    }
                    final selected = controller.selectedCurrencies;
                    if (selected.isEmpty) {
                      return const Text(
                        'No currencies selected',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      );
                    }
                    final preview = selected.take(4).map((c) => c).join(', ');
                    final suffix = selected.length > 4 ? ' +${selected.length - 4} more' : '';
                    return Text(
                      'Selected: $preview$suffix',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    );
                  }),
                  leading: const Icon(
                    Icons.currency_exchange,
                    color: AppColors.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const Divider(color: AppColors.surfaceLight, height: 1),
                ListTile(
                  title: const Text(
                    'Default Currency',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Used for conversion & PDF export',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.primary,
                  ),
                  trailing: Obx(() {
                    final options = controller.selectedCurrencies;
                    final value = controller.defaultCurrency.value;
                    if (options.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return DropdownButton<String>(
                      value: options.contains(value) ? value : options.first,
                      dropdownColor: AppColors.surfaceLight,
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.primary,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.setDefaultCurrency(newValue);
                        }
                      },
                      items: options
                          .map(
                            (code) => DropdownMenuItem(
                              value: code,
                              child: SizedBox(
                                width: 200,
                                child: Text(
                                  currency_names.CurrencyNames.display(code),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _openCurrencyPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) {
        return _CurrencyPickerSheet(controller: controller);
      },
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final ProfileController controller;

  const _CurrencyPickerSheet({required this.controller});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    widget.controller.refreshCurrencyOptions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 520,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.currency_exchange,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Select Currencies',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                setState(() {
                  _query = value.trim().toUpperCase();
                });
              },
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search currency code (e.g., USD)',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final selected = widget.controller.selectedCurrencies;
                final options = widget.controller.currencyOptions.isEmpty
                    ? selected
                    : widget.controller.currencyOptions;
                final filtered =
                    (_query.isEmpty
                          ? options
                          : options
                                .where(
                                  (code) => code.contains(
                                    _query.toUpperCase(),
                                  ),
                                )
                                .toList())
                      ..sort((a, b) {
                        final aSelected = selected.contains(a);
                        final bSelected = selected.contains(b);
                        if (aSelected != bSelected) {
                          return aSelected ? -1 : 1;
                        }
                        return a.compareTo(b);
                      });

                if (widget.controller.isCurrencyLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }
                if (options.isEmpty) {
                  final error = widget.controller.currencyError.value;
                  return Center(
                    child: Text(
                      error == null || error.isEmpty
                          ? 'Currency list unavailable'
                          : error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final code = filtered[index];
                    final isChecked = selected.contains(code);
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) {
                        widget.controller.toggleCurrencySelection(
                          code,
                          val ?? false,
                        );
                        setState(() {});
                      },
                      title: Text(
                        currency_names.CurrencyNames.display(code),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      activeColor: AppColors.primary,
                      checkColor: Colors.black,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compass section ────────────────────────────────────────────────────────

class _CompassSection extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final heading = controller.compassHeading.value;
      final available = controller.isCompassAvailable.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.explore_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Compass',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Transform.rotate(
                    angle: (heading * 3.141592653589793) / 180,
                    child: Icon(
                      Icons.navigation,
                      color: available
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Heading',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        available
                            ? '${heading.toStringAsFixed(0)}°'
                            : 'Compass unavailable',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                  size: 18,
                ),
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
            Obx(
              () => DropdownButton<int>(
                value: controller.selectedTimezoneIndex.value,
                dropdownColor: AppColors.surfaceLight,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primary,
                ),
                onChanged: (int? newIndex) {
                  if (newIndex != null) {
                    controller.setTimezoneIndex(newIndex);
                  }
                },
                items: List.generate(
                  controller.timezones.length,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      controller.timezones[index].code,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          // Rebuild every tick
          controller.currentTime.value; // subscribe
          final tz =
              controller.timezones[controller.selectedTimezoneIndex.value];
          return _TzCard(tz: tz);
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
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
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
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
