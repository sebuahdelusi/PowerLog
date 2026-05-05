import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../utils/currency_converter.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/analytics_controller.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadData,
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (controller.appliances.isEmpty) {
          return _buildEmptyState(
            icon: Icons.kitchen_outlined,
            title: 'No appliances yet',
            subtitle: 'Add your devices to estimate token duration.',
            actionLabel: 'Add Appliances',
            onAction: _goToAppliances,
          );
        }

        if (controller.latestToken.value == null) {
          return _buildEmptyState(
            icon: Icons.payments_outlined,
            title: 'No token data yet',
            subtitle: 'Confirm a token in Home to get duration estimates.',
            actionLabel: 'Confirm Token',
            onAction: _goToHome,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTokenCard(context),
                const SizedBox(height: 16),
                _buildUsageCard(),
                if (controller.isOverCapacity) ...[
                  const SizedBox(height: 12),
                  _buildCapacityWarning(),
                ],
                const SizedBox(height: 20),
                const Text(
                  'Appliance Breakdown',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildApplianceList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTokenCard(BuildContext context) {
    final duration = controller.estimatedDurationLabel;
    final durationText = duration.isEmpty ? 'Not enough data' : duration;
    final token = controller.latestToken.value;
    final rate = controller.effectiveRatePerKwh;
    final includeTax = token?.includeTax ?? controller.tariffConfig.includeTax;
    final taxNote = includeTax ? 'incl tax' : 'excl tax';
    final includeFee =
      token?.includeFixedFee ?? controller.tariffConfig.includeFixedFee;
    final fixedFee = token?.fixedFee ?? controller.tariffConfig.fixedFee;
    final feeNote = includeFee && fixedFee > 0
      ? ' + fixed fee ${_formatCurrency(fixedFee)}'
      : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003545), Color(0xFF001A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined,
              color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Estimated Token Duration',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            durationText,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Token: ${_formatCurrency(controller.tokenIdr)}  •  ${controller.tokenKwh.toStringAsFixed(2)} kWh',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showCurrencySheet(context, controller.tokenIdr),
            child: const Text(
              'convert ↔',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Token date: ${controller.tokenDateLabel}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated end: ${controller.estimatedEndDateLabel}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'Plan: ${controller.tariffPlanLabel}  •  Meter: ${controller.meterCapacityLabel}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            'Rate used: ${_formatCurrency(rate)}/kWh ($taxNote)$feeNote',
            style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 11),
          ),
          if (controller.capacityCheckNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              controller.capacityCheckNote,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Daily Usage Summary',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildKeyValue('Total power', '${controller.totalWatt.toStringAsFixed(0)} W'),
          _buildKeyValue('Daily usage', '${controller.totalDailyKwh.toStringAsFixed(2)} kWh'),
          _buildKeyValue('Appliances', '${controller.appliances.length} items'),
        ],
      ),
    );
  }

  Widget _buildCapacityWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Total power exceeds your meter capacity. Consider upgrading your meter.',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceList() {
    final list = controller.sortedAppliances;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final app = list[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.electrical_services_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${app.wattage.toStringAsFixed(0)} W • ${app.hoursPerDay.toStringAsFixed(1)} h/day',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '${app.dailyKwh.toStringAsFixed(2)} kWh',
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeyValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
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

  void _goToHome() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changePage(0);
      return;
    }
    Get.offAllNamed('/dashboard');
  }

  void _goToAppliances() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changePage(2);
      return;
    }
    Get.offAllNamed('/dashboard');
  }
}

String _formatCurrency(double amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
}
