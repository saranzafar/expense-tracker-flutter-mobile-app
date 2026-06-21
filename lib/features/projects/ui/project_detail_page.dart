import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import 'project_form_page.dart';

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({super.key, required this.project});
  final ProjectRow project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(projectPaymentsProvider(project.id));
    final currency = ref.watch(currencyProvider);
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catName = cats
        .where((c) => c.id == project.categoryId)
        .map((c) => c.name)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProjectFormPage(existing: project),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: paymentsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (payments) {
          final paidMinor =
              payments.fold(0, (s, p) => s + p.amountMinor);
          final remaining = project.totalAmountMinor - paidMinor;
          final progress =
              (paidMinor / project.totalAmountMinor).clamp(0.0, 1.0);
          final isDone = remaining <= 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            children: [
              // ── Header card ───────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDone ? AppColors.greenSoft : Colors.transparent,
                  border: Border.all(color: context.hairline),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (catName != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenSoft,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(catName,
                                      style: AppTextStyles.caption.copyWith(
                                          color: context.ink,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11)),
                                ),
                              Text(project.name,
                                  style: AppTextStyles.headline
                                      .copyWith(color: context.ink)),
                              if (project.description?.isNotEmpty == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(project.description!,
                                      style: AppTextStyles.body.copyWith(
                                          color: context.inkMuted)),
                                ),
                            ],
                          ),
                        ),
                        if (isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text('Completed',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    if (project.endDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${formatShortDate(project.startDate)} → ${formatShortDate(project.endDate!)}',
                        style: AppTextStyles.caption
                            .copyWith(color: context.inkSubtle),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: context.hairline,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.green),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatChip(
                          label: 'Total',
                          value: formatMoney(
                              project.totalAmountMinor, currency),
                          color: context.inkMuted,
                        ),
                        _StatChip(
                          label: 'Paid',
                          value: formatMoney(paidMinor, currency),
                          color: AppColors.green,
                        ),
                        _StatChip(
                          label: isDone ? 'Extra' : 'Remaining',
                          value: formatMoney(remaining.abs(), currency),
                          color: isDone
                              ? AppColors.green
                              : context.inkMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Timeline ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment history',
                      style: AppTextStyles.title
                          .copyWith(color: context.ink)),
                  TextButton.icon(
                    onPressed: () =>
                        _showAddPaymentSheet(context, ref, project),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No payments yet',
                      style: AppTextStyles.body
                          .copyWith(color: context.inkMuted),
                    ),
                  ),
                )
              else
                for (int i = 0; i < payments.length; i++)
                  _TimelineStep(
                    payment: payments[i],
                    currency: currency,
                    isFirst: i == 0,
                    isLast: i == payments.length - 1 && isDone,
                    stepNumber: i + 1,
                    onDelete: () => ref
                        .read(databaseProvider)
                        .deleteProjectPayment(payments[i].id),
                  ),

              // Remaining step (if not done)
              if (!isDone && payments.isNotEmpty)
                _RemainingStep(
                  remaining: remaining,
                  currency: currency,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete project?'),
        content: const Text(
            'This will delete the project and all payment history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deleteProject(project.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

// ── Add Payment Sheet ─────────────────────────────────────────────────────────

Future<void> _showAddPaymentSheet(
    BuildContext context, WidgetRef ref, ProjectRow project) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddPaymentSheet(project: project),
  );
}

class _AddPaymentSheet extends ConsumerStatefulWidget {
  const _AddPaymentSheet({required this.project});
  final ProjectRow project;

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DateTime _paidAt;

  @override
  void initState() {
    super.initState();
    _paidAt = DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final minor = int.parse(_amount.text) * 100;
    await ref.read(databaseProvider).addProjectPayment(
          projectId: widget.project.id,
          projectName: widget.project.name,
          projectCategoryId: widget.project.categoryId,
          amountMinor: minor,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          paidAt: _paidAt,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Add payment',
                    style: AppTextStyles.headline
                        .copyWith(color: context.ink)),
                const SizedBox(height: 20),
                Text('Amount (${currency.code})',
                    style: AppTextStyles.caption
                        .copyWith(color: context.inkMuted)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amount,
                  autofocus: true,
                  style: AppTextStyles.display
                      .copyWith(fontSize: 32, color: context.ink),
                  decoration: InputDecoration(
                    prefixText: '${currency.symbol}  ',
                    hintText: '0',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Note (optional)',
                    style: AppTextStyles.caption
                        .copyWith(color: context.inkMuted)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _note,
                  decoration:
                      const InputDecoration(hintText: 'e.g. Second installment'),
                ),
                const SizedBox(height: 20),
                Text('Date',
                    style: AppTextStyles.caption
                        .copyWith(color: context.inkMuted)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _paidAt,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && mounted) {
                      setState(() => _paidAt = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.hairline),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 18, color: context.inkSubtle),
                        const SizedBox(width: 12),
                        Text(formatShortDate(_paidAt),
                            style: AppTextStyles.body
                                .copyWith(color: context.ink)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.ink,
                  ),
                  onPressed: _save,
                  child: const Text('Save payment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Timeline Widgets ──────────────────────────────────────────────────────────

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.payment,
    required this.currency,
    required this.isFirst,
    required this.isLast,
    required this.stepNumber,
    required this.onDelete,
  });
  final ProjectPaymentRow payment;
  final CurrencyOption currency;
  final bool isFirst;
  final bool isLast;
  final int stepNumber;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + line column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.green, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.green.withValues(alpha: 0.3),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: context.hairline),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatMoney(payment.amountMinor, currency),
                            style: AppTextStyles.title
                                .copyWith(color: context.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatShortDate(payment.paidAt),
                            style: AppTextStyles.caption
                                .copyWith(color: context.inkMuted),
                          ),
                          if (payment.note?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              payment.note!,
                              style: AppTextStyles.caption
                                  .copyWith(color: context.inkSubtle),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: context.inkSubtle),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingStep extends StatelessWidget {
  const _RemainingStep({required this.remaining, required this.currency});
  final int remaining;
  final CurrencyOption currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.hairline, width: 2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.hairline.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatMoney(remaining, currency)} remaining',
                    style: AppTextStyles.body
                        .copyWith(color: context.inkMuted),
                  ),
                  Text(
                    'Tap "Add" to record next payment',
                    style: AppTextStyles.caption
                        .copyWith(color: context.inkSubtle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(color: context.inkSubtle)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.title
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
