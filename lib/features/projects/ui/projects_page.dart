import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/formatters.dart';
import '../../../core/motion.dart';
import '../../../core/theme.dart';
import '../../../data/database.dart';
import '../../../data/providers.dart';
import '../../../data/settings_repo.dart';
import 'project_detail_page.dart';
import 'project_form_page.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final projects = ref.watch(projectsProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ProjectFormPage(),
            )),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: XSwitcher(
          child: projects.when(
            loading: () => const Center(
                key: ValueKey('proj-loading'),
                child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(key: const ValueKey('proj-error'), child: Text('$e')),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  key: const ValueKey('proj-empty'),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_outlined,
                            size: 56, color: context.inkSubtle),
                        const SizedBox(height: 16),
                        Text('No projects yet',
                            style: AppTextStyles.title
                                .copyWith(color: context.ink)),
                        const SizedBox(height: 6),
                        Text('Tap + to create your first project',
                            style: AppTextStyles.caption
                                .copyWith(color: context.inkMuted),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                key: const ValueKey('proj-list'),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                itemCount: items.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FadeIn(
                    key: ValueKey(items[i].id),
                    child: _ProjectCard(
                      project: items[i],
                      currency: currency,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProjectDetailPage(project: items[i]),
                        ),
                      ),
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

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({
    required this.project,
    required this.currency,
    required this.onTap,
  });
  final ProjectRow project;
  final CurrencyOption currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(projectPaymentsProvider(project.id));
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catName = cats
        .where((c) => c.id == project.categoryId)
        .map((c) => c.name)
        .firstOrNull;

    return paymentsAsync.when(
      loading: () => _CardShell(project: project, catName: catName,
          onTap: onTap, currency: currency, paidMinor: 0),
      error: (_, __) => _CardShell(project: project, catName: catName,
          onTap: onTap, currency: currency, paidMinor: 0),
      data: (payments) {
        final paid = payments.fold(0, (s, p) => s + p.amountMinor);
        return _CardShell(
          project: project,
          catName: catName,
          onTap: onTap,
          currency: currency,
          paidMinor: paid,
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.project,
    required this.catName,
    required this.onTap,
    required this.currency,
    required this.paidMinor,
  });
  final ProjectRow project;
  final String? catName;
  final VoidCallback onTap;
  final CurrencyOption currency;
  final int paidMinor;

  @override
  Widget build(BuildContext context) {
    final progress =
        (paidMinor / project.totalAmountMinor).clamp(0.0, 1.0);
    final isDone = paidMinor >= project.totalAmountMinor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
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
                      Text(project.name,
                          style: AppTextStyles.title
                              .copyWith(color: context.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (project.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(project.description!,
                            style: AppTextStyles.caption
                                .copyWith(color: context.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                if (catName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(catName!,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: context.hairline,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.green),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatMoney(paidMinor, currency)} paid',
                  style: AppTextStyles.caption.copyWith(
                      color:
                          isDone ? AppColors.green : context.inkMuted),
                ),
                Text(
                  'of ${formatMoney(project.totalAmountMinor, currency)}',
                  style: AppTextStyles.caption
                      .copyWith(color: context.inkSubtle),
                ),
              ],
            ),
            if (project.endDate != null) ...[
              const SizedBox(height: 6),
              Text(
                '${formatShortDate(project.startDate)} → ${formatShortDate(project.endDate!)}',
                style: AppTextStyles.caption
                    .copyWith(color: context.inkSubtle, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
