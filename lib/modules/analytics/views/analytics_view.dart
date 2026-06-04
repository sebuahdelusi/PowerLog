import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import 'package:powerlog/utils/currency_names.dart' as currency_names;
import '../../../services/exchange_rate_service.dart';
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
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
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
                _buildTokenLog(),
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
                    fontWeight: FontWeight.w600,
                  ),
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 32),
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showCurrencySheet(context, controller.tokenIdr),
            child: const Text(
              'convert ↔',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Token date: ${controller.tokenDateLabel}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated end: ${controller.estimatedEndDateLabel}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Plan: ${controller.tariffPlanLabel}  •  Meter: ${controller.meterCapacityLabel}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rate used: ${_formatCurrency(rate)}/kWh ($taxNote)$feeNote',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 11,
            ),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildKeyValue(
            'Total power',
            '${controller.totalWatt.toStringAsFixed(0)} W',
          ),
          _buildKeyValue(
            'Daily usage',
            '${controller.totalDailyKwh.toStringAsFixed(2)} kWh',
          ),
          _buildKeyValue('Appliances', '${controller.appliances.length} items'),
        ],
      ),
    );
  }

  Widget _buildTokenLog() {
    return Obx(() {
      final items = controller.tokens.take(6).toList();
      if (items.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Token Log',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((token) {
              final inputAt = _formatInputAt(token.inputAt, token.date);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatCurrency(token.amountIdr),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Token date: ${_formatTokenDate(token.date)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      inputAt,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await Get.dialog<bool>(
                          AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text(
                              'Delete Token',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            content: const Text(
                              'Delete this token entry?',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Get.back(result: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) controller.deleteToken(token.id!);
                      },
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
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
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 18,
          ),
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
                child: const Icon(
                  Icons.electrical_services_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${app.wattage.toStringAsFixed(0)} W • ${app.hoursPerDay.toStringAsFixed(1)} h/day',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${app.dailyKwh.toStringAsFixed(2)} kWh',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
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
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
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
    final exchange = Get.find<ExchangeRateService>();
    var currencies = <String>[];
    var selected = '';
    var rates = <String, double>{};
    var isRateLoading = true;
    var rateError = '';
    void Function(void Function())? sheetSetState;
    var isSheetOpen = true;

    Future<void> loadSheetData() async {
      final selectedList = await exchange.getSelectedCurrencies();
      final defaultCode = await exchange.getDefaultCurrency();
      final nextCurrencies = selectedList.isNotEmpty
          ? selectedList
          : ['USD', 'EUR', 'GBP'];
      final nextSelected = nextCurrencies.contains(defaultCode)
          ? defaultCode
          : nextCurrencies.first;

      if (isSheetOpen && (Get.isBottomSheetOpen ?? false)) {
        sheetSetState?.call(() {
          currencies = nextCurrencies;
          selected = nextSelected;
        });
      }

      var fetchedRates = await exchange.getRates('idr');
      if (fetchedRates.isEmpty) {
        fetchedRates = await exchange.getRates('idr', forceRefresh: true);
      }
      if (isSheetOpen && (Get.isBottomSheetOpen ?? false)) {
        sheetSetState?.call(() {
          rates = fetchedRates;
          isRateLoading = false;
          rateError = exchange.lastError ?? '';
        });
      }
    }

    final sheet = Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          sheetSetState = setState;
          final list = currencies.isNotEmpty
              ? currencies
              : ['USD', 'EUR', 'GBP'];
          final active = selected.isNotEmpty
              ? selected
              : (list.contains('USD') ? 'USD' : list.first);
          final rate = rates[active] ?? 0;
          final hasRate = rate > 0;
          final converted = idrAmount * rate;

          return Container(
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
                    const Icon(
                      Icons.currency_exchange,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Token Conversion',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Base: ${_formatCurrency(idrAmount)} IDR',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Divider(color: AppColors.surfaceLight, height: 24),
                Row(
                  children: [
                    const Text(
                      'Convert to:',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: active,
                        dropdownColor: AppColors.surfaceLight,
                        underline: const SizedBox(),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.primary,
                        ),
                        selectedItemBuilder: (ctx) {
                          return list
                              .map(
                                (code) => Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    code,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList();
                        },
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            await exchange.setDefaultCurrency(newValue);
                            setState(() {
                              selected = newValue;
                            });
                          }
                        },
                        items: list.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              currency_names.CurrencyNames.display(value),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
                          active,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          hasRate
                              ? exchange.format(active, converted)
                              : (isRateLoading
                                    ? 'Loading rates...'
                                    : (rateError.isNotEmpty
                                          ? rateError
                                          : 'Rate unavailable')),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    loadSheetData();
    sheet.whenComplete(() {
      isSheetOpen = false;
    });
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
  return Get.find<ExchangeRateService>().formatIdrToDefault(amount);
}

String _formatTokenDate(String value) {
  try {
    return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(value));
  } catch (_) {
    return value;
  }
}

String _formatInputAt(String? value, String fallbackDate) {
  if (value == null || value.isEmpty) {
    return _formatTokenDate(fallbackDate);
  }
  try {
    final parsed = DateTime.parse(value);
    return DateFormat('d MMM yyyy • HH:mm').format(parsed);
  } catch (_) {
    return value;
  }
}
