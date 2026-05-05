import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../utils/currency_converter.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PowerLog'),
        actions: [
          // Torch indicator
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.flashlight_on,
                  color: controller.isTorchOn.value
                      ? AppColors.secondary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  size: 20,
                ),
              )),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: controller.refreshEstimator,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _GyroHeader(),
            _EstimatorCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/chat'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text('AI Tips',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Gyroscope tilt header ─────────────────────────────────────────────────────

class _GyroHeader extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Normalize to subtle tilt: max ±0.06 radians
      final tiltX = (controller.gyroX.value / 5.0) * 0.06;
      final tiltY = (controller.gyroY.value / 5.0) * 0.06;

      return Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(-tiltX)
          ..rotateY(tiltY),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF003545), Color(0xFF001A2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Animated electric icon
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Icon(Icons.bolt, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Electricity Monitor',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tilt your phone to see the effect ↕',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // PLN button
              GestureDetector(
                onTap: controller.goToNearestPln,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'PLN',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Game button
              GestureDetector(
                onTap: () => Get.toNamed('/game'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎮', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'Game',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Token estimator ─────────────────────────────────────────────────────────

class _EstimatorCard extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.battery_charging_full,
                    color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Token Estimator',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final plans = controller.tariffPlans;
            final current = controller.tariffPlanCode.value;
            final value = plans.any((p) => p.code == current)
                ? current
                : plans.first.code;

            return DropdownButtonFormField<String>(
              key: ValueKey(value),
              initialValue: value,
              dropdownColor: AppColors.surfaceLight,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (String? code) {
                if (code != null) {
                  controller.setTariffPlan(code);
                }
              },
              decoration: InputDecoration(
                labelText: 'Tariff Plan',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              items: plans
                  .map((plan) => DropdownMenuItem<String>(
                        value: plan.code,
                        child: Text(plan.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.event,
                  color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => Text(
                      'Token date: ${controller.tokenDateLabel}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    )),
              ),
              TextButton(
                onPressed: () => _pickTokenDate(context),
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final label = controller.meterCapacityLabel;
            final note = controller.capacityCheckNote;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed,
                          color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Meter capacity: $label',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: TextStyle(
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ]
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.tokenCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Token Amount (IDR)',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintText: 'e.g. 50000',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
              prefixIcon: const Icon(Icons.payments_outlined,
                  color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showCurrencySheet(context, controller.tokenIdr),
              child: const Text('Convert ↔'),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.isAppliancesLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (controller.appliances.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.kitchen_outlined,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No appliances yet. Add your devices to estimate usage.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: controller.goToAppliances,
                      child: const Text('Add'),
                    )
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.kitchen_outlined,
                          color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Appliances: ${controller.appliances.length}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: controller.goToAppliances,
                        child: const Text('Manage'),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total power: ${controller.totalWatt.toStringAsFixed(0)} W',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Daily usage: ${controller.totalDailyKwh.toStringAsFixed(2)} kWh',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          Obx(() {
            final label = controller.estimatedDurationLabel;
            if (label.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: AppColors.secondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Token lasts about $label',
                      style: const TextStyle(
                          color: AppColors.secondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            if (!controller.isOverCapacity) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total power exceeds your meter capacity. Consider upgrading your meter.',
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          Obx(() {
            final cfg = controller.tariffConfig;
            final rate = controller.effectiveRatePerKwh;
            final taxNote = cfg.includeTax ? 'incl tax' : 'excl tax';
            final feeNote = cfg.includeFixedFee && cfg.fixedFee > 0
                ? ' + fixed fee ${_formatCurrency(cfg.fixedFee)}'
                : '';

            return Text(
              'Rate used: ${_formatCurrency(rate)}/kWh ($taxNote)$feeNote',
              style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 11),
            );
          }),
          const SizedBox(height: 16),
          Obx(() => SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: controller.isConfirming.value
                      ? null
                      : controller.confirmToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: controller.isConfirming.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    controller.isConfirming.value
                        ? 'Saving...'
                        : 'Confirm Token',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _pickTokenDate(BuildContext context) async {
    final initial = controller.tokenDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.setTokenDate(picked);
    }
  }

  void _showCurrencySheet(BuildContext context, double idrAmount) {
    var selected = CurrencyConverter.currencies.first;
    final converted = CurrencyConverter.fromIDR(idrAmount);

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.currency_exchange, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Text('Token Conversion',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Base: ${_formatCurrency(idrAmount)} IDR',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const Divider(color: AppColors.surfaceLight, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Convert to:',
                      style: TextStyle(color: AppColors.textPrimary)),
                  DropdownButton<String>(
                    value: selected,
                    dropdownColor: AppColors.surfaceLight,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.primary),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selected = newValue;
                        });
                      }
                    },
                    items: CurrencyConverter.currencies
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        CurrencyConverter.symbols[selected]!,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selected,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              letterSpacing: 1)),
                      Text(
                        CurrencyConverter.format(
                            selected, converted[selected] ?? 0),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatCurrency(double amount) {
  return NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(amount);
}
