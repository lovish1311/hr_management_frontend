import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/query_ast.dart';
import '../data/models/query_metadata.dart';
import '../data/models/query_template.dart';
import '../data/services/query_builder_api_client.dart';

/// Cached Metadata Catalog Provider
final queryMetadataProvider = FutureProvider<MetadataCatalog>((ref) async {
  return await QueryBuilderApiClient.fetchMetadata();
});

/// Immutable UI & Filter State for Query Builder
class QueryBuilderState {
  final String rootEntity; // "EMPLOYEE", "ATTENDANCE", "LEAVES", "PAYROLL"
  final List<String> selectedFieldIds;
  final Map<String, String> columnAliases;
  final FilterGroup filterGroup;
  final String? sortBy;
  final String sortDirection; // "ASC" | "DESC"
  final int activeStep; // 0: Domain, 1: Fields, 2: Rules, 3: Preview
  final String? quickDepartment;
  final String? quickStatus;
  final String? quickPeriodMonth;
  final int page;
  final int pageSize;
  final bool isExporting;

  const QueryBuilderState({
    required this.rootEntity,
    required this.selectedFieldIds,
    this.columnAliases = const {},
    required this.filterGroup,
    this.sortBy,
    this.sortDirection = 'ASC',
    this.activeStep = 0,
    this.quickDepartment,
    this.quickStatus,
    this.quickPeriodMonth,
    this.page = 0,
    this.pageSize = 50,
    this.isExporting = false,
  });

  QueryBuilderState copyWith({
    String? rootEntity,
    List<String>? selectedFieldIds,
    Map<String, String>? columnAliases,
    FilterGroup? filterGroup,
    String? sortBy,
    String? sortDirection,
    int? activeStep,
    String? quickDepartment,
    bool clearQuickDepartment = false,
    String? quickStatus,
    bool clearQuickStatus = false,
    String? quickPeriodMonth,
    bool clearQuickPeriodMonth = false,
    int? page,
    int? pageSize,
    bool? isExporting,
  }) {
    return QueryBuilderState(
      rootEntity: rootEntity ?? this.rootEntity,
      selectedFieldIds: selectedFieldIds ?? this.selectedFieldIds,
      columnAliases: columnAliases ?? this.columnAliases,
      filterGroup: filterGroup ?? this.filterGroup,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      activeStep: activeStep ?? this.activeStep,
      quickDepartment: clearQuickDepartment ? null : (quickDepartment ?? this.quickDepartment),
      quickStatus: clearQuickStatus ? null : (quickStatus ?? this.quickStatus),
      quickPeriodMonth: clearQuickPeriodMonth ? null : (quickPeriodMonth ?? this.quickPeriodMonth),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isExporting: isExporting ?? this.isExporting,
    );
  }

  QueryRequest toRequest() {
    final quickRules = <FilterRule>[];
    if (quickDepartment != null && quickDepartment!.isNotEmpty) {
      quickRules.add(FilterRule(
        fieldId: 'employee.department',
        operator: 'EQUALS',
        values: [quickDepartment!],
      ));
    }

    if (quickStatus != null && quickStatus!.isNotEmpty) {
      quickRules.add(FilterRule(
        fieldId: 'employee.status',
        operator: 'EQUALS',
        values: [quickStatus!],
      ));
    }

    if (quickPeriodMonth != null && quickPeriodMonth!.isNotEmpty && rootEntity.toUpperCase() == 'PAYROLL') {
      quickRules.add(FilterRule(
        fieldId: 'payroll.payrollMonth',
        operator: 'EQUALS',
        values: [quickPeriodMonth!],
      ));
    }

    final FilterGroup mergedGroup;
    if (quickRules.isEmpty) {
      mergedGroup = filterGroup;
    } else if (filterGroup.conjunction == 'OR' &&
        (filterGroup.rules.isNotEmpty || filterGroup.subGroups.isNotEmpty)) {
      // Wrap user's OR group and quick filters under a top-level AND group
      mergedGroup = FilterGroup(
        conjunction: 'AND',
        subGroups: [filterGroup],
        rules: quickRules,
      );
    } else {
      final combinedRules = List<FilterRule>.from(filterGroup.rules);
      if (quickDepartment != null && quickDepartment!.isNotEmpty) {
        combinedRules.removeWhere((r) => r.fieldId == 'employee.department');
        combinedRules.add(FilterRule(
          fieldId: 'employee.department',
          operator: 'EQUALS',
          values: [quickDepartment!],
        ));
      }

      if (quickStatus != null && quickStatus!.isNotEmpty) {
        combinedRules.removeWhere((r) => r.fieldId == 'employee.status');
        combinedRules.add(FilterRule(
          fieldId: 'employee.status',
          operator: 'EQUALS',
          values: [quickStatus!],
        ));
      }

      if (quickPeriodMonth != null && quickPeriodMonth!.isNotEmpty && rootEntity.toUpperCase() == 'PAYROLL') {
        combinedRules.removeWhere((r) => r.fieldId == 'payroll.payrollMonth');
        combinedRules.add(FilterRule(
          fieldId: 'payroll.payrollMonth',
          operator: 'EQUALS',
          values: [quickPeriodMonth!],
        ));
      }
      mergedGroup = filterGroup.copyWith(rules: combinedRules);
    }

    return QueryRequest(
      rootEntity: rootEntity,
      selectedFields: selectedFieldIds,
      columnAliases: columnAliases,
      filterGroup: mergedGroup,
      sortBy: sortBy,
      sortDirection: sortDirection,
      page: page,
      pageSize: pageSize,
    );
  }
}

/// Query Builder State Notifier
class QueryBuilderNotifier extends Notifier<QueryBuilderState> {
  @override
  QueryBuilderState build() {
    return const QueryBuilderState(
      rootEntity: 'EMPLOYEE',
      selectedFieldIds: [
        'employee.code',
        'employee.fullName',
        'employee.department',
        'employee.status',
      ],
      filterGroup: FilterGroup(),
    );
  }

  void setRootEntity(String entityId, MetadataCatalog? catalog) {
    // Choose default fields for the selected entity
    List<String> defaultFields = [];
    if (catalog != null) {
      final ent = catalog.findEntity(entityId);
      if (ent != null) {
        defaultFields = ent.fields.take(5).map((f) => f.fieldId).toList();
      }
    }
    if (defaultFields.isEmpty) {
      defaultFields = ['employee.code', 'employee.fullName'];
    }

    state = state.copyWith(
      rootEntity: entityId,
      selectedFieldIds: defaultFields,
      filterGroup: const FilterGroup(),
      clearQuickDepartment: true,
      clearQuickStatus: true,
      clearQuickPeriodMonth: true,
      page: 0,
    );
  }

  void setActiveStep(int step) {
    state = state.copyWith(activeStep: step);
  }

  void toggleField(String fieldId) {
    final list = List<String>.from(state.selectedFieldIds);
    if (list.contains(fieldId)) {
      if (list.length > 1) { // keep at least 1 field
        list.remove(fieldId);
      }
    } else {
      list.add(fieldId);
    }
    state = state.copyWith(selectedFieldIds: list);
  }

  void setSelectedFields(List<String> fields) {
    if (fields.isNotEmpty) {
      state = state.copyWith(selectedFieldIds: fields);
    }
  }

  void reorderFields(int oldIndex, int newIndex) {
    final list = List<String>.from(state.selectedFieldIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(selectedFieldIds: list);
  }

  void setQuickDepartment(String? dept) {
    if (state.quickDepartment == dept) {
      state = state.copyWith(clearQuickDepartment: true, page: 0);
    } else {
      state = state.copyWith(quickDepartment: dept, page: 0);
    }
  }

  void setQuickStatus(String? status) {
    if (state.quickStatus == status) {
      state = state.copyWith(clearQuickStatus: true, page: 0);
    } else {
      state = state.copyWith(quickStatus: status, page: 0);
    }
  }

  void setQuickPeriodMonth(String? month) {
    if (state.quickPeriodMonth == month) {
      state = state.copyWith(clearQuickPeriodMonth: true, page: 0);
    } else {
      state = state.copyWith(quickPeriodMonth: month, page: 0);
    }
  }

  void updateFilterGroup(FilterGroup group) {
    state = state.copyWith(filterGroup: group, page: 0);
  }

  void addRuleToRoot(FilterRule rule) {
    final rules = List<FilterRule>.from(state.filterGroup.rules)..add(rule);
    state = state.copyWith(
      filterGroup: state.filterGroup.copyWith(rules: rules),
      page: 0,
    );
  }

  void removeRuleFromRoot(int index) {
    final rules = List<FilterRule>.from(state.filterGroup.rules);
    if (index >= 0 && index < rules.length) {
      rules.removeAt(index);
      state = state.copyWith(
        filterGroup: state.filterGroup.copyWith(rules: rules),
        page: 0,
      );
    }
  }

  void setConjunction(String conj) {
    state = state.copyWith(
      filterGroup: state.filterGroup.copyWith(conjunction: conj),
      page: 0,
    );
  }

  void setSorting(String fieldId) {
    if (state.sortBy == fieldId) {
      final newDir = state.sortDirection == 'ASC' ? 'DESC' : 'ASC';
      state = state.copyWith(sortDirection: newDir, page: 0);
    } else {
      state = state.copyWith(sortBy: fieldId, sortDirection: 'ASC', page: 0);
    }
  }

  void setPage(int newPage) {
    state = state.copyWith(page: newPage);
  }

  void setExporting(bool exporting) {
    state = state.copyWith(isExporting: exporting);
  }

  void loadTemplate(QueryTemplate template) {
    final req = template.queryConfig;
    state = state.copyWith(
      rootEntity: req.rootEntity,
      selectedFieldIds: req.selectedFields.isNotEmpty
          ? req.selectedFields
          : ['employee.code', 'employee.fullName'],
      columnAliases: req.columnAliases,
      filterGroup: req.filterGroup,
      sortBy: req.sortBy,
      sortDirection: req.sortDirection,
      clearQuickDepartment: true,
      clearQuickStatus: true,
      clearQuickPeriodMonth: true,
      page: 0,
      activeStep: 3, // jump straight to preview
    );
  }
}

final queryBuilderNotifierProvider =
    NotifierProvider<QueryBuilderNotifier, QueryBuilderState>(QueryBuilderNotifier.new);

/// Debounced count provider: waits 350ms before triggering /api/query-builder/count
final queryCountProvider = FutureProvider<QueryCountResult>((ref) async {
  final queryState = ref.watch(queryBuilderNotifierProvider);
  final req = queryState.toRequest();

  // 350ms debounce
  await Future.delayed(const Duration(milliseconds: 350));

  try {
    return await QueryBuilderApiClient.countQuery(req);
  } catch (e) {
    return const QueryCountResult(estimatedCount: 0, executionTimeMs: 0);
  }
});

/// Live Paginated Preview Provider (debounced 350ms to prevent request flood)
class QueryPreviewNotifier extends AsyncNotifier<QueryPreviewResult> {
  @override
  Future<QueryPreviewResult> build() async {
    final queryState = ref.watch(queryBuilderNotifierProvider);
    final req = queryState.toRequest();

    // 350ms debounce to prevent request storms on rapid filter edits
    await Future.delayed(const Duration(milliseconds: 350));

    return await QueryBuilderApiClient.previewQuery(req);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final queryState = ref.read(queryBuilderNotifierProvider);
      return await QueryBuilderApiClient.previewQuery(queryState.toRequest());
    });
  }
}

final queryPreviewProvider =
    AsyncNotifierProvider<QueryPreviewNotifier, QueryPreviewResult>(QueryPreviewNotifier.new);

/// Templates AsyncNotifier Provider
class QueryTemplatesNotifier extends AsyncNotifier<List<QueryTemplate>> {
  @override
  Future<List<QueryTemplate>> build() async {
    return await QueryBuilderApiClient.getTemplates();
  }

  Future<void> saveTemplate(QueryTemplate template) async {
    await QueryBuilderApiClient.createTemplate(template);
    ref.invalidateSelf();
  }

  Future<void> removeTemplate(int id) async {
    await QueryBuilderApiClient.deleteTemplate(id);
    ref.invalidateSelf();
  }
}

final queryTemplatesProvider =
    AsyncNotifierProvider<QueryTemplatesNotifier, List<QueryTemplate>>(QueryTemplatesNotifier.new);
