import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  Future<void> _addCategory() async {
    String inputText = '';
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Salary, Food'),
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
                foregroundColor: AppColors.ink),
            onPressed: () => Navigator.pop(ctx, inputText.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final existing = ref
        .read(categoriesProvider)
        .valueOrNull
        ?.where((c) => c.name.toLowerCase() == name.toLowerCase());
    if (existing?.isNotEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" already exists')),
      );
      return;
    }

    await ref.read(databaseProvider).addCategory(name);
  }

  Future<void> _renameCategory(CategoryRow cat) async {
    String inputText = cat.name;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename category'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          controller: TextEditingController(text: cat.name),
          decoration: const InputDecoration(hintText: 'Category name'),
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
                foregroundColor: AppColors.ink),
            onPressed: () => Navigator.pop(ctx, inputText.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == cat.name || !mounted) return;
    await ref.read(databaseProvider).renameCategory(cat.id, name);
  }

  Future<void> _deleteCategory(CategoryRow cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${cat.name}"?'),
        content: const Text(
            'Existing records and projects with this category will become uncategorized.'),
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
    if (ok != true || !mounted) return;
    await ref.read(databaseProvider).deleteCategory(cat.id);
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCategory,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: XSwitcher(
          child: cats.isEmpty
              ? Center(
                  key: const ValueKey('cats-empty'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_outline,
                          size: 56, color: context.inkSubtle),
                      const SizedBox(height: 16),
                      Text('No categories yet',
                          style:
                              AppTextStyles.title.copyWith(color: context.ink)),
                      const SizedBox(height: 6),
                      Text('Tap + to add your first category',
                          style: AppTextStyles.caption
                              .copyWith(color: context.inkMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  key: const ValueKey('cats-list'),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 1),
                  itemBuilder: (_, i) {
                    final cat = cats[i];
                    return FadeIn(
                      key: ValueKey(cat.id),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: context.hairline),
                          borderRadius: BorderRadius.circular(14),
                          color: context.cardSurface,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.greenSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.label_outline,
                                size: 18, color: AppColors.green),
                          ),
                          title: Text(cat.name,
                              style:
                                  AppTextStyles.body.copyWith(color: context.ink,
                                  fontWeight: FontWeight.w600)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined,
                                    size: 20, color: context.inkMuted),
                                onPressed: () => _renameCategory(cat),
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: AppColors.danger),
                                onPressed: () => _deleteCategory(cat),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
