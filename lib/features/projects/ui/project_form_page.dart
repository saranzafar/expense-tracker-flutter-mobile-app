import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';

const _uuid = Uuid();

class ProjectFormPage extends ConsumerStatefulWidget {
  const ProjectFormPage({super.key, this.existing});
  final ProjectRow? existing;

  @override
  ConsumerState<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends ConsumerState<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _totalAmount;
  late TextEditingController _advance;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _totalAmount = TextEditingController(
        text: e == null ? '' : (e.totalAmountMinor / 100).toStringAsFixed(0));
    _advance = TextEditingController();
    _startDate = e?.startDate ?? DateTime.now();
    _endDate = e?.endDate;
    _selectedCategoryId = e?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _totalAmount.dispose();
    _advance.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _addCategory() async {
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    String inputText = '';
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Construction, IT'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final total = int.parse(_totalAmount.text) * 100;
    final advanceText = _advance.text.trim();
    final advanceMinor =
        advanceText.isEmpty ? 0 : (int.tryParse(advanceText) ?? 0) * 100;
    final id = widget.existing?.id ?? _uuid.v4();

    final db = ref.read(databaseProvider);
    await db.upsertProject(ProjectsCompanion(
      id: Value(id),
      name: Value(_name.text.trim()),
      description: Value(_description.text.trim().isEmpty
          ? null
          : _description.text.trim()),
      categoryId: Value(_selectedCategoryId),
      totalAmountMinor: Value(total),
      startDate: Value(_startDate),
      endDate: Value(_endDate),
    ));

    // If this is a new project and advance is provided, add first payment.
    // This also creates an income record so the advance lands in the balance.
    if (!_isEdit && advanceMinor > 0) {
      await db.addProjectPayment(
        projectId: id,
        projectName: _name.text.trim(),
        projectCategoryId: _selectedCategoryId,
        amountMinor: advanceMinor,
        note: 'Advance',
        paidAt: _startDate,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final captionMuted =
        AppTextStyles.caption.copyWith(color: context.inkMuted);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit project' : 'New project')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Project name', style: captionMuted),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Home renovation'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            Text('Description (optional)', style: captionMuted),
            const SizedBox(height: 8),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(hintText: 'Short note'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Text('Total amount (${currency.code})', style: captionMuted),
            const SizedBox(height: 8),
            TextFormField(
              controller: _totalAmount,
              style: AppTextStyles.display
                  .copyWith(fontSize: 32, color: context.ink),
              decoration: InputDecoration(
                prefixText: '${currency.symbol}  ',
                hintText: '0',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 20),
              Text('Advance payment (optional, ${currency.code})',
                  style: captionMuted),
              const SizedBox(height: 8),
              TextFormField(
                controller: _advance,
                decoration: InputDecoration(
                  prefixText: '${currency.symbol}  ',
                  hintText: '0',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            const SizedBox(height: 20),
            Text('Category (optional)', style: captionMuted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in cats)
                  _CatChip(
                    label: cat.name,
                    selected: _selectedCategoryId == cat.id,
                    onTap: () => setState(() => _selectedCategoryId =
                        _selectedCategoryId == cat.id ? null : cat.id),
                  ),
                _CatChip(
                  label: '+ Add',
                  selected: false,
                  onTap: _addCategory,
                  isAdd: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Start date', style: captionMuted),
            const SizedBox(height: 8),
            _DateTile(
              value: _startDate,
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 20),
            Text('End date (optional)', style: captionMuted),
            const SizedBox(height: 8),
            _DateTile(
              value: _endDate,
              placeholder: 'No end date',
              onTap: () => _pickDate(isStart: false),
              onClear: _endDate != null
                  ? () => setState(() => _endDate = null)
                  : null,
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.ink,
              ),
              onPressed: _save,
              child: Text(_isEdit ? 'Save changes' : 'Create project'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAdd = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.ink : Colors.transparent,
          border: Border.all(
              color: selected ? context.ink : context.hairline, width: 1.5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(
              color: selected
                  ? context.surface
                  : context.inkSubtle,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            )),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.onTap,
    this.value,
    this.placeholder,
    this.onClear,
  });
  final DateTime? value;
  final String? placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            Expanded(
              child: Text(
                value != null
                    ? formatShortDate(value!)
                    : (placeholder ?? 'Select date'),
                style: AppTextStyles.body.copyWith(
                    color:
                        value != null ? context.ink : context.inkSubtle),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 18, color: context.inkSubtle),
              ),
          ],
        ),
      ),
    );
  }
}
