class QueryRequest {
  final String rootEntity;
  final List<String> selectedFields;
  final Map<String, String> columnAliases;
  final FilterGroup filterGroup;
  final String? sortBy;
  final String sortDirection; // "ASC" | "DESC"
  final int page;
  final int pageSize;

  const QueryRequest({
    required this.rootEntity,
    required this.selectedFields,
    this.columnAliases = const {},
    required this.filterGroup,
    this.sortBy,
    this.sortDirection = 'ASC',
    this.page = 0,
    this.pageSize = 50,
  });

  Map<String, dynamic> toJson() {
    return {
      'rootEntity': rootEntity,
      'selectedFields': selectedFields,
      'columnAliases': columnAliases,
      'filterGroup': filterGroup.toJson(),
      if (sortBy != null && sortBy!.isNotEmpty) 'sortBy': sortBy,
      'sortDirection': sortDirection,
      'page': page,
      'pageSize': pageSize,
    };
  }

  factory QueryRequest.fromJson(Map<String, dynamic> json) {
    return QueryRequest(
      rootEntity: json['rootEntity'] as String? ?? 'EMPLOYEE',
      selectedFields: (json['selectedFields'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      columnAliases: (json['columnAliases'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
      filterGroup: json['filterGroup'] != null
          ? FilterGroup.fromJson(json['filterGroup'] as Map<String, dynamic>)
          : const FilterGroup(),
      sortBy: json['sortBy'] as String?,
      sortDirection: json['sortDirection'] as String? ?? 'ASC',
      page: json['page'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 50,
    );
  }

  QueryRequest copyWith({
    String? rootEntity,
    List<String>? selectedFields,
    Map<String, String>? columnAliases,
    FilterGroup? filterGroup,
    String? sortBy,
    String? sortDirection,
    int? page,
    int? pageSize,
  }) {
    return QueryRequest(
      rootEntity: rootEntity ?? this.rootEntity,
      selectedFields: selectedFields ?? this.selectedFields,
      columnAliases: columnAliases ?? this.columnAliases,
      filterGroup: filterGroup ?? this.filterGroup,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class FilterGroup {
  final String conjunction; // "AND" | "OR"
  final List<FilterRule> rules;
  final List<FilterGroup> subGroups;

  const FilterGroup({
    this.conjunction = 'AND',
    this.rules = const [],
    this.subGroups = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'conjunction': conjunction,
      'rules': rules.map((r) => r.toJson()).toList(),
      'subGroups': subGroups.map((g) => g.toJson()).toList(),
    };
  }

  factory FilterGroup.fromJson(Map<String, dynamic> json) {
    return FilterGroup(
      conjunction: json['conjunction'] as String? ?? 'AND',
      rules: (json['rules'] as List<dynamic>? ?? [])
          .map((r) => FilterRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      subGroups: (json['subGroups'] as List<dynamic>? ?? [])
          .map((g) => FilterGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  FilterGroup copyWith({
    String? conjunction,
    List<FilterRule>? rules,
    List<FilterGroup>? subGroups,
  }) {
    return FilterGroup(
      conjunction: conjunction ?? this.conjunction,
      rules: rules ?? this.rules,
      subGroups: subGroups ?? this.subGroups,
    );
  }

  bool get isEmpty => rules.isEmpty && subGroups.every((g) => g.isEmpty);
}

class FilterRule {
  final String fieldId;
  final String operator; // EQUALS, NOT_EQUALS, CONTAINS, STARTS_WITH, ENDS_WITH, GREATER_THAN, LESS_THAN, BETWEEN, IN, BEFORE, AFTER
  final List<String> values;

  const FilterRule({
    required this.fieldId,
    required this.operator,
    required this.values,
  });

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
      'operator': operator,
      'values': values,
    };
  }

  factory FilterRule.fromJson(Map<String, dynamic> json) {
    return FilterRule(
      fieldId: json['fieldId'] as String? ?? '',
      operator: json['operator'] as String? ?? 'EQUALS',
      values: (json['values'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  FilterRule copyWith({
    String? fieldId,
    String? operator,
    List<String>? values,
  }) {
    return FilterRule(
      fieldId: fieldId ?? this.fieldId,
      operator: operator ?? this.operator,
      values: values ?? this.values,
    );
  }
}

class ColumnMeta {
  final String fieldId;
  final String label;
  final String dataType;

  const ColumnMeta({
    required this.fieldId,
    required this.label,
    required this.dataType,
  });

  factory ColumnMeta.fromJson(Map<String, dynamic> json) {
    return ColumnMeta(
      fieldId: json['fieldId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      dataType: json['dataType'] as String? ?? 'STRING',
    );
  }
}

class KpiSummary {
  final int totalRecords;
  final double? sumNetTakeHome;
  final double? sumGrossEarnings;
  final double? totalLeaves;
  final double? totalLopDays;

  const KpiSummary({
    required this.totalRecords,
    this.sumNetTakeHome,
    this.sumGrossEarnings,
    this.totalLeaves,
    this.totalLopDays,
  });

  factory KpiSummary.fromJson(Map<String, dynamic> json) {
    return KpiSummary(
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      sumNetTakeHome: (json['sumNetTakeHome'] as num?)?.toDouble(),
      sumGrossEarnings: (json['sumGrossEarnings'] as num?)?.toDouble(),
      totalLeaves: (json['totalLeaves'] as num?)?.toDouble(),
      totalLopDays: (json['totalLopDays'] as num?)?.toDouble(),
    );
  }
}

class QueryPreviewResult {
  final List<ColumnMeta> columns;
  final List<Map<String, dynamic>> rows;
  final int totalMatchingRecords;
  final KpiSummary? kpiSummary;
  final int currentPage;
  final int pageSize;
  final int executionTimeMs;

  const QueryPreviewResult({
    required this.columns,
    required this.rows,
    required this.totalMatchingRecords,
    this.kpiSummary,
    this.currentPage = 0,
    this.pageSize = 50,
    this.executionTimeMs = 0,
  });

  factory QueryPreviewResult.fromJson(Map<String, dynamic> json) {
    return QueryPreviewResult(
      columns: (json['columns'] as List<dynamic>? ?? [])
          .map((c) => ColumnMeta.fromJson(c as Map<String, dynamic>))
          .toList(),
      rows: (json['rows'] as List<dynamic>? ?? [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList(),
      totalMatchingRecords: (json['totalMatchingRecords'] as num?)?.toInt() ?? 0,
      kpiSummary: json['kpiSummary'] != null
          ? KpiSummary.fromJson(json['kpiSummary'] as Map<String, dynamic>)
          : null,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 50,
      executionTimeMs: (json['executionTimeMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class QueryCountResult {
  final int estimatedCount;
  final int executionTimeMs;

  const QueryCountResult({
    required this.estimatedCount,
    required this.executionTimeMs,
  });

  factory QueryCountResult.fromJson(Map<String, dynamic> json) {
    return QueryCountResult(
      estimatedCount: (json['estimatedCount'] as num?)?.toInt() ?? 0,
      executionTimeMs: (json['executionTimeMs'] as num?)?.toInt() ?? 0,
    );
  }
}
