import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/log_model.dart';
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
            onPressed: controller.loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  _GyroHeader(),
                  _InputCard(),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          _SectionHeader(),
          Expanded(child: _LogList()),
        ],
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

// ── Input card ────────────────────────────────────────────────────────────────

class _InputCard extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
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
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Log Usage',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // kWh input
            TextFormField(
              controller: controller.kwhCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => controller.kwhInput.value = v,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter kWh usage';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid positive number';
                return null;
              },
              decoration: InputDecoration(
                labelText: 'kWh Usage',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: 'e.g. 12.5',
                hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5)),
                suffixText: 'kWh',
                suffixStyle: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.electrical_services_outlined,
                    color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Live cost preview
            Obx(() {
              final kwh =
                  double.tryParse(controller.kwhInput.value.trim()) ?? 0;
              final cost = controller.previewCost;
              if (kwh <= 0) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money,
                        color: AppColors.secondary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Estimated cost: ${_formatCurrency(cost)}',
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }),

            // Error
            Obx(() => controller.errorMessage.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(controller.errorMessage.value,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  )
                : const SizedBox.shrink()),

            const SizedBox(height: 16),

            // Save button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.isSaving.value ? null : controller.addLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      controller.isSaving.value ? 'Saving…' : 'Save Log',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Section header & Search ──────────────────────────────────────────────────

class _SectionHeader extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Usage History',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${controller.filteredLogs.length}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  )),
              const Spacer(),
              const Text('Swipe to delete',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          // Search Field
          TextField(
            onChanged: (v) => controller.searchQuery.value = v,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by date or kWh...',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Log list ──────────────────────────────────────────────────────────────────

class _LogList extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      final list = controller.filteredLogs;
      if (list.isEmpty) return _EmptyState();
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: list.length,
        itemBuilder: (ctx, i) => _LogItem(log: list[i]),
      );
    });
  }
}

// ── Single log item with swipe-to-delete ─────────────────────────────────────

class _LogItem extends GetView<HomeController> {
  final LogModel log;
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      onDismissed: (_) => controller.deleteLog(log.id!),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.bolt, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(log.date),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.electrical_services,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${log.kwhUsage.toStringAsFixed(2)} kWh',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_formatCurrency(log.estimatedCost),
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                // Currency convert button
                GestureDetector(
                  onTap: () => _showCurrencySheet(context),
                  child: const Text(
                    'convert ↔',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySheet(BuildContext context) {
    final converted = CurrencyConverter.fromIDR(log.estimatedCost);
    Get.bottomSheet(
      Container(
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
                const Text('Currency Conversion',
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
              'Base: ${_formatCurrency(log.estimatedCost)} IDR',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const Divider(color: AppColors.surfaceLight, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Convert to:', style: TextStyle(color: AppColors.textPrimary)),
                Obx(() => DropdownButton<String>(
                  value: controller.selectedCurrency.value,
                  dropdownColor: AppColors.surfaceLight,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.selectedCurrency.value = newValue;
                    }
                  },
                  items: CurrencyConverter.currencies
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                )),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final code = controller.selectedCurrency.value;
              final amount = converted[code]!;
              return Row(
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
                        CurrencyConverter.symbols[code]!,
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
                      Text(code,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              letterSpacing: 1)),
                      Text(
                        CurrencyConverter.format(code, amount),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Rates are approximate (Updated 2026)',
                style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('No logs yet',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Add your first electricity usage above',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
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
