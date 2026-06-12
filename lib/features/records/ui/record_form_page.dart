import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';

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
  String? _selectedCategoryId;

  bool get _isLoan =>
      _type == RecordType.loanGiven || _type == RecordType.loanTaken;
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
    _selectedCategoryId = e?.categoryId;
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
        return '$action loan given';
      case RecordType.loanTaken:
        return '$action loan taken';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final captionMuted =
        AppTextStyles.caption.copyWith(color: context.inkMuted);
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
            Text('Amount (${currency.code})', style: captionMuted),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amount,
              autofocus: !_isEdit,
              style: AppTextStyles.display
                  .copyWith(fontSize: 32, color: context.ink),
              decoration: InputDecoration(
                prefixText: '${currency.symbol}  ',
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
            AnimatedSize(
              duration: AppMotion.med,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: !_isLoan
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _type == RecordType.loanTaken
                              ? 'From whom'
                              : 'To whom',
                          style: captionMuted,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _counterparty,
                          decoration: const InputDecoration(hintText: 'Name'),
                          validator: (v) {
                            if (!_isLoan) return null;
                            if (v == null || v.trim().isEmpty) return 'Required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
            Text('Description', style: captionMuted),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                hintText: 'Optional note',
              ),
              maxLines: 2,
            ),
            AnimatedSize(
              duration: AppMotion.med,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: _isLoan
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text('Category', style: captionMuted),
                        const SizedBox(height: 8),
                        _CategoryPicker(
                          selected: _selectedCategoryId,
                          onChanged: (id) =>
                              setState(() => _selectedCategoryId = id),
                          onAdd: _addCategory,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Text('Date', style: captionMuted),
            const SizedBox(height: 8),
            _DateField(
              value: _occurredAt,
              onPick: (d) => setState(() => _occurredAt = d),
            ),
            AnimatedSize(
              duration: AppMotion.med,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: !_isLoan
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          _type == RecordType.loanTaken
                              ? 'Expected repayment date'
                              : 'Expected return date',
                          style: captionMuted,
                        ),
                        const SizedBox(height: 8),
                        _DateField(
                          value: _expectedReturnAt,
                          placeholder: 'Pick a date',
                          onPick: (d) =>
                              setState(() => _expectedReturnAt = d),
                          onClear: () =>
                              setState(() => _expectedReturnAt = null),
                        ),
                      ],
                    ),
            ),
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
      categoryId: Value(!_isLoan ? _selectedCategoryId : null),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addCategory() async {
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    // Capture text via onChanged — no TextEditingController needed.
    // Using a controller + ctrl.dispose() right after showDialog resolves
    // causes a crash because the dialog close animation still renders the
    // TextField for ~200ms after the Future completes, and addListener on a
    // disposed controller throws '_dependents.isEmpty is not true'.
    String inputText = '';
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration:
              const InputDecoration(hintText: 'e.g. Food, Transport'),
          onChanged: (v) => inputText = v,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.ink,
            ),
            onPressed: () => Navigator.pop(ctx, inputText.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final existing =
        cats.where((c) => c.name.toLowerCase() == name.toLowerCase());
    if (existing.isNotEmpty) {
      setState(() => _selectedCategoryId = existing.first.id);
      return;
    }
    final row = await ref.read(databaseProvider).addCategory(name);
    if (!mounted) return;
    setState(() => _selectedCategoryId = row.id);
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

class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({
    required this.selected,
    required this.onChanged,
    required this.onAdd,
  });
  final String? selected;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final cat in cats) ...[
            _CategoryChip(
              label: cat.name,
              isSelected: selected == cat.id,
              onTap: () => onChanged(selected == cat.id ? null : cat.id),
            ),
            const SizedBox(width: 8),
          ],
          _AddCategoryChip(onAdd: onAdd),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.ink : Colors.transparent,
          border: Border.all(
              color: isSelected ? context.ink : context.hairline),
          borderRadius: BorderRadius.circular(100),
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.fast,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? context.surface : context.ink,
            fontWeight: FontWeight.w600,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _AddCategoryChip extends StatelessWidget {
  const _AddCategoryChip({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: context.inkMuted),
            const SizedBox(width: 4),
            Text('Add',
                style: AppTextStyles.caption
                    .copyWith(color: context.inkMuted)),
          ],
        ),
      ),
    );
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
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: context.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null
                    ? formatDate(value!)
                    : (placeholder ?? 'Pick a date'),
                style: AppTextStyles.body.copyWith(
                    color: value != null
                        ? context.ink
                        : context.inkSubtle),
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
