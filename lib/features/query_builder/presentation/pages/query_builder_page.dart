import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/utils/file_downloader.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import '../../data/models/query_ast.dart';
import '../../data/models/query_metadata.dart';
import '../../data/services/query_builder_api_client.dart';
import '../../providers/query_builder_providers.dart';
import '../widgets/entity_selector_card.dart';
import '../widgets/field_transfer_list.dart';
import '../widgets/visual_rule_builder.dart';
import '../widgets/quick_filter_bar.dart';
import '../widgets/kpi_metrics_banner.dart';
import '../widgets/data_preview_table.dart';
import '../widgets/report_gallery_card.dart';
import '../widgets/template_management_dialog.dart';
import '../widgets/query_builder_skeleton.dart';

class QueryBuilderPage extends ConsumerStatefulWidget {
  const QueryBuilderPage({super.key});

  @override
  ConsumerState<QueryBuilderPage> createState() => _QueryBuilderPageState();
}

class _QueryBuilderPageState extends ConsumerState<QueryBuilderPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleExport(String format) async {
    final notifier = ref.read(queryBuilderNotifierProvider.notifier);
    final state = ref.read(queryBuilderNotifierProvider);

    notifier.setExporting(true);
    try {
      final bytes = await QueryBuilderApiClient.exportReport(state.toRequest(), format: format);
      final isCsv = format.toUpperCase() == 'CSV';
      final ext = isCsv ? 'csv' : 'xlsx';
      final mime = isCsv
          ? 'text/csv'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final fileName = 'TeamJoy_Report_${state.rootEntity.toLowerCase()}_$dateStr.$ext';

      final savedPath = await FileDownloader.downloadBytes(
        bytes: bytes,
        fileName: fileName,
        mimeType: mime,
      );

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Report saved successfully!\n$savedPath'),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Report export cancelled or storage location not accessible.'),
                  ),
                ],
              ),
              backgroundColor: Colors.amber.shade900,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        notifier.setExporting(false);
      }
    }
  }

  void _openTemplateDialog(MetadataCatalog catalog) {
    final state = ref.read(queryBuilderNotifierProvider);

    showDialog(
      context: context,
      builder: (ctx) => TemplateManagementDialog(
        currentRequest: state.toRequest(),
        onLoadTemplate: (tmpl) {
          ref.read(queryBuilderNotifierProvider.notifier).loadTemplate(tmpl);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded template: "${tmpl.name}"'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final metadataAsync = ref.watch(queryMetadataProvider);
    final queryState = ref.watch(queryBuilderNotifierProvider);
    final notifier = ref.read(queryBuilderNotifierProvider.notifier);
    final countAsync = ref.watch(queryCountProvider);
    final previewAsync = ref.watch(queryPreviewProvider);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Enterprise Report & Query Builder'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_rounded),
            tooltip: 'Manage Templates',
            onPressed: () {
              metadataAsync.whenData((catalog) => _openTemplateDialog(catalog));
            },
          ),
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: PopupMenuThemeData(
                color: t.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: t.border),
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Export Report',
              enabled: !queryState.isExporting,
              icon: queryState.isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded),
              onSelected: (fmt) => _handleExport(fmt),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'XLSX',
                  child: Row(
                    children: [
                      Icon(Icons.table_view_rounded, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Export as Excel (.xlsx)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'CSV',
                  child: Row(
                    children: [
                      Icon(Icons.description_rounded, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Export as CSV (.csv)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Desktop Header with title and actions
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: t.card,
                  border: Border(bottom: BorderSide(color: t.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.analytics_rounded, color: t.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enterprise Report & Query Builder',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: t.onBackgroundText,
                          ),
                        ),
                        Text(
                          'Visually filter workforce datasets, preview aggregates, and stream Excel reports.',
                          style: TextStyle(fontSize: 12, color: t.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    countAsync.when(
                      data: (cnt) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: t.cardSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list_rounded, size: 14, color: t.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${cnt.estimatedCount} records',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: t.surfaceText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: t.cardSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: t.primary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Counting...',
                              style: TextStyle(fontSize: 11, color: t.surfaceTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_add_rounded, size: 16),
                      label: const Text('Templates'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: t.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        metadataAsync.whenData((catalog) => _openTemplateDialog(catalog));
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: queryState.isExporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 16),
                      label: Text(queryState.isExporting ? 'Exporting...' : 'Export (.xlsx)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: queryState.isExporting ? null : () => _handleExport('XLSX'),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: metadataAsync.when(
        loading: () => const QueryBuilderPageSkeleton(),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text('Failed to load metadata catalog', style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                const SizedBox(height: 6),
                Text('$err', style: TextStyle(fontSize: 12, color: t.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry Connection'),
                  onPressed: () => ref.invalidate(queryMetadataProvider),
                ),
              ],
            ),
          ),
        ),
        data: (catalog) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              if (width < 650) {
                // Mobile View: 4-Step Wizard (<650dp)
                return _buildMobileWizardLayout(
                  context,
                  t,
                  catalog,
                  queryState,
                  notifier,
                  countAsync,
                  previewAsync,
                );
              } else if (width < 1100) {
                // Tablet View: Two-Column Split (650 - 1099dp)
                return _buildTabletSplitLayout(
                  context,
                  t,
                  catalog,
                  queryState,
                  notifier,
                  countAsync,
                  previewAsync,
                );
              } else {
                // Desktop View: Unified Three-Column Canvas (>= 1100dp)
                return _buildDesktopCanvasLayout(
                  context,
                  t,
                  catalog,
                  queryState,
                  notifier,
                  countAsync,
                  previewAsync,
                );
              }
            },
          );
        },
      ),
    ),
    ],
    ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP NAVIGATION BUTTONS (Modern, Premium, Responsive)
  // ---------------------------------------------------------------------------
  Widget _buildStepNavigation({
    required dynamic t,
    VoidCallback? onBack,
    String? backLabel,
    VoidCallback? onNext,
    String? nextLabel,
    IconData? nextIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              flex: onNext != null ? 4 : 1,
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: t.cardSoft.withValues(alpha: 0.5),
                    foregroundColor: t.surfaceText,
                    side: BorderSide(color: t.border, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_rounded, size: 16, color: t.surfaceText),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          backLabel ?? 'Back',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: t.surfaceText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (onBack != null && onNext != null) const SizedBox(width: 12),
          if (onNext != null)
            Expanded(
              flex: onBack != null ? 6 : 1,
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shadowColor: t.primary.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          nextLabel ?? 'Next',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        nextIcon ?? Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
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

  // ---------------------------------------------------------------------------
  // 1. MOBILE 4-STEP WIZARD (< 650 dp)
  // ---------------------------------------------------------------------------
  Widget _buildMobileWizardLayout(
    BuildContext context,
    dynamic t,
    MetadataCatalog catalog,
    QueryBuilderState queryState,
    QueryBuilderNotifier notifier,
    AsyncValue<QueryCountResult> countAsync,
    AsyncValue<QueryPreviewResult> previewAsync,
  ) {
    final stepTitles = ['1. Domain', '2. Columns', '3. Filters', '4. Preview'];

    return Column(
      children: [
        // Stepper Navigation Bar
        Container(
          color: t.card,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < stepTitles.length; i++) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => notifier.setActiveStep(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: queryState.activeStep == i ? t.primary : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          stepTitles[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: queryState.activeStep == i ? FontWeight.bold : FontWeight.normal,
                            color: queryState.activeStep == i ? t.primary : t.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: t.border),

        // Step Content with SingleChildScrollView for zero overflow
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (queryState.activeStep == 0) ...[
                  ReportGalleryCard(onSelectTemplate: (tmpl) => notifier.loadTemplate(tmpl)),
                  const SizedBox(height: 16),
                  EntitySelectorCard(
                    entities: catalog.entities,
                    selectedEntityId: queryState.rootEntity,
                    onSelectEntity: (id) => notifier.setRootEntity(id, catalog),
                  ),
                  const SizedBox(height: 16),
                  _buildStepNavigation(
                    t: t,
                    onNext: () => notifier.setActiveStep(1),
                    nextLabel: 'Next: Choose Columns',
                    nextIcon: Icons.arrow_forward_rounded,
                  ),
                ] else if (queryState.activeStep == 1) ...[
                  FieldTransferList(
                    catalog: catalog,
                    activeEntityId: queryState.rootEntity,
                    selectedFieldIds: queryState.selectedFieldIds,
                    onToggleField: (f) => notifier.toggleField(f),
                    onReorderFields: (oldIdx, newIdx) => notifier.reorderFields(oldIdx, newIdx),
                  ),
                  const SizedBox(height: 16),
                  _buildStepNavigation(
                    t: t,
                    onBack: () => notifier.setActiveStep(0),
                    backLabel: 'Back',
                    onNext: () => notifier.setActiveStep(2),
                    nextLabel: 'Next: Filter Rules',
                    nextIcon: Icons.arrow_forward_rounded,
                  ),
                ] else if (queryState.activeStep == 2) ...[
                  QuickFilterBar(
                    selectedDepartment: queryState.quickDepartment,
                    selectedStatus: queryState.quickStatus,
                    selectedMonth: queryState.quickPeriodMonth,
                    showMonthFilter: queryState.rootEntity == 'PAYROLL',
                    onDepartmentChanged: (dept) => notifier.setQuickDepartment(dept),
                    onStatusChanged: (st) => notifier.setQuickStatus(st),
                    onMonthChanged: (m) => notifier.setQuickPeriodMonth(m),
                  ),
                  const SizedBox(height: 14),
                  VisualRuleBuilder(
                    catalog: catalog,
                    rootEntity: queryState.rootEntity,
                    filterGroup: queryState.filterGroup,
                    onGroupChanged: (g) => notifier.updateFilterGroup(g),
                  ),
                  const SizedBox(height: 16),
                  _buildStepNavigation(
                    t: t,
                    onBack: () => notifier.setActiveStep(1),
                    backLabel: 'Back',
                    onNext: () => notifier.setActiveStep(3),
                    nextLabel: 'Preview Report Data',
                    nextIcon: Icons.table_chart_rounded,
                  ),
                ] else if (queryState.activeStep == 3) ...[
                  _buildPreviewPane(
                    t: t,
                    queryState: queryState,
                    notifier: notifier,
                    previewAsync: previewAsync,
                    footer: _buildStepNavigation(
                      t: t,
                      onBack: () => notifier.setActiveStep(2),
                      backLabel: 'Modify Filters & Rules',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. TABLET TWO-COLUMN SPLIT (650 - 1099 dp)
  // ---------------------------------------------------------------------------
  Widget _buildTabletSplitLayout(
    BuildContext context,
    dynamic t,
    MetadataCatalog catalog,
    QueryBuilderState queryState,
    QueryBuilderNotifier notifier,
    AsyncValue<QueryCountResult> countAsync,
    AsyncValue<QueryPreviewResult> previewAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Configuration Controls (Domain, Fields, Filters)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportGalleryCard(onSelectTemplate: (tmpl) => notifier.loadTemplate(tmpl)),
                  const SizedBox(height: 14),
                  EntitySelectorCard(
                    entities: catalog.entities,
                    selectedEntityId: queryState.rootEntity,
                    onSelectEntity: (id) => notifier.setRootEntity(id, catalog),
                  ),
                  const SizedBox(height: 14),
                  FieldTransferList(
                    catalog: catalog,
                    activeEntityId: queryState.rootEntity,
                    selectedFieldIds: queryState.selectedFieldIds,
                    onToggleField: (f) => notifier.toggleField(f),
                    onReorderFields: (oldIdx, newIdx) => notifier.reorderFields(oldIdx, newIdx),
                  ),
                  const SizedBox(height: 14),
                  QuickFilterBar(
                    selectedDepartment: queryState.quickDepartment,
                    selectedStatus: queryState.quickStatus,
                    selectedMonth: queryState.quickPeriodMonth,
                    showMonthFilter: queryState.rootEntity == 'PAYROLL',
                    onDepartmentChanged: (dept) => notifier.setQuickDepartment(dept),
                    onStatusChanged: (st) => notifier.setQuickStatus(st),
                    onMonthChanged: (m) => notifier.setQuickPeriodMonth(m),
                  ),
                  const SizedBox(height: 12),
                  VisualRuleBuilder(
                    catalog: catalog,
                    rootEntity: queryState.rootEntity,
                    filterGroup: queryState.filterGroup,
                    onGroupChanged: (g) => notifier.updateFilterGroup(g),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Right Column: Live Preview & KPIs
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildPreviewPane(
                t: t,
                queryState: queryState,
                notifier: notifier,
                previewAsync: previewAsync,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. DESKTOP UNIFIED THREE-COLUMN CANVAS (>= 1100 dp)
  // ---------------------------------------------------------------------------
  Widget _buildDesktopCanvasLayout(
    BuildContext context,
    dynamic t,
    MetadataCatalog catalog,
    QueryBuilderState queryState,
    QueryBuilderNotifier notifier,
    AsyncValue<QueryCountResult> countAsync,
    AsyncValue<QueryPreviewResult> previewAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Bar: Prebuilt Report Gallery & Quick Filters
          ReportGalleryCard(onSelectTemplate: (tmpl) => notifier.loadTemplate(tmpl)),
          const SizedBox(height: 12),
          QuickFilterBar(
            selectedDepartment: queryState.quickDepartment,
            selectedStatus: queryState.quickStatus,
            selectedMonth: queryState.quickPeriodMonth,
            showMonthFilter: queryState.rootEntity == 'PAYROLL',
            onDepartmentChanged: (dept) => notifier.setQuickDepartment(dept),
            onStatusChanged: (st) => notifier.setQuickStatus(st),
            onMonthChanged: (m) => notifier.setQuickPeriodMonth(m),
          ),
          const SizedBox(height: 14),

          // Three-Column Split Canvas
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Col 1: Entity & Field Catalog
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EntitySelectorCard(
                          entities: catalog.entities,
                          selectedEntityId: queryState.rootEntity,
                          onSelectEntity: (id) => notifier.setRootEntity(id, catalog),
                        ),
                        const SizedBox(height: 14),
                        FieldTransferList(
                          catalog: catalog,
                          activeEntityId: queryState.rootEntity,
                          selectedFieldIds: queryState.selectedFieldIds,
                          onToggleField: (f) => notifier.toggleField(f),
                          onReorderFields: (oldIdx, newIdx) => notifier.reorderFields(oldIdx, newIdx),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Col 2: Recursive AST Rule Builder
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_tree_rounded, size: 18, color: t.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Visual AST Filter Tree',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: t.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        VisualRuleBuilder(
                          catalog: catalog,
                          rootEntity: queryState.rootEntity,
                          filterGroup: queryState.filterGroup,
                          onGroupChanged: (g) => notifier.updateFilterGroup(g),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Col 3: Live 2D Pinned Preview Grid & Live KPIs
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildPreviewPane(
                      t: t,
                      queryState: queryState,
                      notifier: notifier,
                      previewAsync: previewAsync,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPane({
    required dynamic t,
    required QueryBuilderState queryState,
    required QueryBuilderNotifier notifier,
    required AsyncValue<QueryPreviewResult> previewAsync,
    Widget? footer,
  }) {
    return previewAsync.when(
      skipLoadingOnReload: true,
      loading: () => const QueryPreviewSkeleton(),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
            const SizedBox(height: 8),
            Text(
              'Failed to load preview: $err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => ref.read(queryPreviewProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Preview'),
            ),
          ],
        ),
      ),
      data: (preview) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KpiMetricsBanner(
              totalMatchingRecords: preview.totalMatchingRecords,
              kpiSummary: preview.kpiSummary,
              executionTimeMs: preview.executionTimeMs,
            ),
            const SizedBox(height: 12),
            DataPreviewTable(
              columns: preview.columns,
              rows: preview.rows,
              sortBy: queryState.sortBy,
              sortDirection: queryState.sortDirection,
              onSortChanged: (s) => notifier.setSorting(s),
              currentPage: queryState.page,
              pageSize: queryState.pageSize,
              totalCount: preview.totalMatchingRecords,
              onPageChanged: (p) => notifier.setPage(p),
              isLoading: previewAsync.isLoading,
            ),
            if (footer != null) ...[
              const SizedBox(height: 14),
              footer,
            ],
          ],
        );
      },
    );
  }
}
