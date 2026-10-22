import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hr_management/features/query_builder/data/models/query_ast.dart';
import 'package:hr_management/features/query_builder/data/models/query_metadata.dart';
import 'package:hr_management/features/query_builder/presentation/pages/query_builder_page.dart';
import 'package:hr_management/features/query_builder/presentation/widgets/data_preview_table.dart';
import 'package:hr_management/features/query_builder/presentation/widgets/entity_selector_card.dart';
import 'package:hr_management/features/query_builder/presentation/widgets/kpi_metrics_banner.dart';
import 'package:hr_management/features/query_builder/presentation/widgets/quick_filter_bar.dart';
import 'package:hr_management/features/query_builder/presentation/widgets/visual_rule_builder.dart';
import 'package:hr_management/features/query_builder/providers/query_builder_providers.dart';

void main() {
  const sampleCatalog = MetadataCatalog(
    entities: [
      EntityMetadata(
        entityId: 'EMPLOYEE',
        displayName: 'Employees & Profiles',
        description: 'Workforce demographics and departments',
        fields: [
          FieldMetadata(fieldId: 'employee.code', label: 'Employee Code', dataType: 'STRING'),
          FieldMetadata(fieldId: 'employee.fullName', label: 'Full Name', dataType: 'STRING'),
          FieldMetadata(
            fieldId: 'employee.department',
            label: 'Department',
            dataType: 'ENUM',
            options: ['Engineering', 'HR', 'Product'],
          ),
          FieldMetadata(
            fieldId: 'employee.status',
            label: 'Employment Status',
            dataType: 'ENUM',
            options: ['ACTIVE', 'PROBATION'],
          ),
        ],
      ),
      EntityMetadata(
        entityId: 'PAYROLL',
        displayName: 'Payroll & Compensation',
        description: 'Monthly compensation and deductions',
        fields: [
          FieldMetadata(fieldId: 'payroll.netTakeHome', label: 'Net Take Home', dataType: 'NUMBER'),
          FieldMetadata(fieldId: 'payroll.totalGrossEarnings', label: 'Gross Earnings', dataType: 'NUMBER'),
        ],
      ),
    ],
  );

  const samplePreview = QueryPreviewResult(
    columns: [
      ColumnMeta(fieldId: 'employee.code', label: 'Employee Code', dataType: 'STRING'),
      ColumnMeta(fieldId: 'employee.fullName', label: 'Employee Name', dataType: 'STRING'),
      ColumnMeta(fieldId: 'employee.department', label: 'Department', dataType: 'ENUM'),
      ColumnMeta(fieldId: 'employee.status', label: 'Status', dataType: 'ENUM'),
      ColumnMeta(fieldId: 'payroll.netTakeHome', label: 'Net Salary', dataType: 'NUMBER'),
    ],
    rows: [
      {
        'employee.code': 'EMP001',
        'employee.fullName': 'Lovish Aggarwal',
        'employee.department': 'Engineering',
        'employee.status': 'ACTIVE',
        'payroll.netTakeHome': 85000.0,
      },
      {
        'employee.code': 'EMP002',
        'employee.fullName': 'Ishu Saini',
        'employee.department': 'Product',
        'employee.status': 'ACTIVE',
        'payroll.netTakeHome': 72000.0,
      },
    ],
    totalMatchingRecords: 2,
    kpiSummary: KpiSummary(
      totalRecords: 2,
      sumNetTakeHome: 157000.0,
      sumGrossEarnings: 180000.0,
    ),
    executionTimeMs: 12,
  );

  Widget createTestWidget({
    required Widget child,
    Size surfaceSize = const Size(360, 640),
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        queryMetadataProvider.overrideWith((ref) => Future.value(sampleCatalog)),
        queryPreviewProvider.overrideWith(() => _MockPreviewNotifier(samplePreview)),
        queryCountProvider.overrideWith((ref) => Future.value(const QueryCountResult(estimatedCount: 2, executionTimeMs: 10))),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: surfaceSize,
            textScaler: TextScaler.linear(textScale),
          ),
          child: SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Query Builder Responsive & Zero-Overflow Audits', () {
    testWidgets('TC-QB-01: QuickFilterBar renders without overflow on 320dp small phone', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(320, 568),
          child: Scaffold(
            body: QuickFilterBar(
              onDepartmentChanged: (_) {},
              onStatusChanged: (_) {},
              onMonthChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Filters:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-QB-02: KpiMetricsBanner renders cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(320, 568),
          child: const Scaffold(
            body: KpiMetricsBanner(
              totalMatchingRecords: 42,
              kpiSummary: KpiSummary(
                totalRecords: 42,
                sumNetTakeHome: 3250000.0,
                sumGrossEarnings: 3890000.0,
              ),
              executionTimeMs: 14,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Matched Records'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-QB-03: EntitySelectorCard renders 4 domains without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(360, 640),
          child: Scaffold(
            body: SingleChildScrollView(
              child: EntitySelectorCard(
                entities: sampleCatalog.entities,
                selectedEntityId: 'EMPLOYEE',
                onSelectEntity: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Primary Domain'), findsOneWidget);
      expect(find.text('Employees & Profiles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-QB-04: VisualRuleBuilder renders rules and conjunction options', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(360, 640),
          child: Scaffold(
            body: SingleChildScrollView(
              child: VisualRuleBuilder(
                catalog: sampleCatalog,
                filterGroup: const FilterGroup(
                  conjunction: 'AND',
                  rules: [
                    FilterRule(fieldId: 'employee.status', operator: 'EQUALS', values: ['ACTIVE']),
                  ],
                ),
                onGroupChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AND (All)'), findsOneWidget);
      expect(find.text('OR (Any)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-QB-05: DataPreviewTable renders 2D grid with sorting headers', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(360, 640),
          child: Scaffold(
            body: SingleChildScrollView(
              child: DataPreviewTable(
                columns: samplePreview.columns,
                rows: samplePreview.rows,
                onSortChanged: (_) {},
                currentPage: 0,
                pageSize: 50,
                totalCount: 2,
                onPageChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Employee Code'), findsOneWidget);
      expect(find.text('EMP001'), findsOneWidget);
      expect(find.text('Lovish Aggarwal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-QB-06: QueryBuilderPage full page renders mobile wizard on 360x640', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(360, 640),
          child: const QueryBuilderPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Enterprise Report & Query Builder'), findsOneWidget);
      expect(find.text('1. Domain'), findsOneWidget);
      expect(find.text('Next: Choose Columns'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-QB-07: QueryBuilderPage renders on 320x568 small phone at 2.0x font scaling without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(320, 568),
          textScale: 2.0,
          child: const QueryBuilderPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final err = tester.takeException();
      expect(err, isNull);
    });

    testWidgets('TC-QB-08: QueryBuilderPage step navigation on 320x568 small phone maintains zero overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(320, 568),
          child: const QueryBuilderPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Advance to Step 2 (Columns)
      final nextButton = find.text('Next: Choose Columns');
      expect(nextButton, findsOneWidget);
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('2. Columns'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Advance to Step 3 (Filters)
      final nextFilters = find.text('Next: Filter Rules');
      expect(nextFilters, findsOneWidget);
      await tester.ensureVisible(nextFilters);
      await tester.tap(nextFilters);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('3. Filters'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Advance to Step 4 (Preview & Export)
      final nextPreview = find.text('Preview Report Data');
      expect(nextPreview, findsOneWidget);
      await tester.ensureVisible(nextPreview);
      await tester.tap(nextPreview);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('4. Preview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-QB-09: QueryBuilderPage desktop renders 2-column canvas and opens Preview Data modal', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(1280, 800),
          child: const QueryBuilderPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Visual AST Filter Tree'), findsOneWidget);
      final previewBtn = find.byKey(const Key('btn_preview_excel_top'));
      expect(previewBtn, findsOneWidget);

      await tester.tap(previewBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Report Data & Excel Preview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TC-QB-10: Preview Data modal renders without RenderFlex overflow on small mobile (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(
          surfaceSize: const Size(360, 640),
          child: const QueryBuilderPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final previewIconBtn = find.byTooltip('Preview Data / Excel');
      expect(previewIconBtn, findsOneWidget);

      await tester.tap(previewIconBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Report Data & Excel Preview'), findsOneWidget);
      expect(find.byTooltip('Export Excel (.xlsx)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify close modal works cleanly
      final closeBtn = find.byTooltip('Close Preview');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

class _MockPreviewNotifier extends QueryPreviewNotifier {
  final QueryPreviewResult _result;
  _MockPreviewNotifier(this._result);

  @override
  Future<QueryPreviewResult> build() async {
    return _result;
  }
}
