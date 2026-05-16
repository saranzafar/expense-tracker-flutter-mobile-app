import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';

class RecordFormPage extends ConsumerStatefulWidget {
  const RecordFormPage({super.key, required this.type, this.existing});

  final RecordType type;
  final RecordRow? existing;

  @override
  ConsumerState<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends ConsumerState<RecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amount;
  late TextEditingController _description;
  late TextEditingController _counterparty;
  late DateTime _occurredAt;
  DateTime? _expectedReturnAt;
  late RecordType _type;

  bool get _isLoan => _type == RecordType.loanGiven;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = widget.type;
    _amount = TextEditingController(
        text: e == null ? '' : (e.amountMinor / 100).toStringAsFixed(0));
    _description = TextEditingController(text: e?.description ?? '');
    _counterparty = TextEditingController(text: e?.counterparty ?? '');
    _occurredAt = e?.occurredAt ?? DateTime.now();
    _expectedReturnAt = e?.expectedReturnAt;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _counterparty.dispose();
    super.dispose();
  }

  String get _title {
    final action = _isEdit ? 'Edit' : 'New';
    switch (_type) {
      case RecordType.expense:
        return '$action expense';
      case RecordType.income:
        return '$action income';
      case RecordType.loanGiven:
        return '$action loan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Amount (PKR)', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amount,
              autofocus: !_isEdit,
              style: AppTextStyles.display.copyWith(fontSize: 32),
              decoration: const InputDecoration(
                prefixText: 'Rs  ',
                hintText: '0',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (_isLoan) ...[
              Text('To whom', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextFormField(
                controller: _counterparty,
                decoration: const InputDecoration(
                  hintText: 'Name',
                ),
                validator: (v) {
                  if (!_isLoan) return null;
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],
            Text('Description', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                hintText: 'Optional note',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Text('Date', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            _DateField(
              value: _occurredAt,
              onPick: (d) => setState(() => _occurredAt = d),
            ),
            if (_isLoan) ...[
              const SizedBox(height: 20),
              Text('Expected return date', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              _DateField(
                value: _expectedReturnAt,
                placeholder: 'Pick a date',
                onPick: (d) => setState(() => _expectedReturnAt = d),
                onClear: () => setState(() => _expectedReturnAt = null),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.ink,
              ),
              onPressed: _save,
              child: Text(_isEdit ? 'Save changes' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final minor = int.parse(_amount.text) * 100;
    final db = ref.read(databaseProvider);
    final id = widget.existing?.id;
    await db.upsertRecord(RecordsCompanion(
      id: id == null ? const Value.absent() : Value(id),
      amountMinor: Value(minor),
      type: Value(_type),
      description: Value(_description.text.trim().isEmpty
          ? null
          : _description.text.trim()),
      occurredAt: Value(_occurredAt),
      counterparty: Value(_isLoan && _counterparty.text.trim().isNotEmpty
          ? _counterparty.text.trim()
          : null),
      expectedReturnAt: Value(_isLoan ? _expectedReturnAt : null),
      returned: Value(widget.existing?.returned ?? false),
      returnedAt: Value(widget.existing?.returnedAt),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deleteRecord(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onPick,
    this.placeholder,
    this.onClear,
  });
  final DateTime? value;
  final String? placeholder;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null
                    ? formatDate(value!)
                    : (placeholder ?? 'Pick a date'),
                style: AppTextStyles.body.copyWith(
                    color: value != null
                        ? AppColors.ink
                        : AppColors.inkSubtle),
              ),
            ),
            if (value != null && onClear != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
