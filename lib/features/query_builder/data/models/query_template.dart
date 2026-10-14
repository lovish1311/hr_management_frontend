import 'query_ast.dart';

class QueryTemplate {
  final int? id;
  final String name;
  final String? description;
  final String? category;
  final bool isPublic;
  final int? createdByEmployeeId;
  final QueryRequest queryConfig;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QueryTemplate({
    this.id,
    required this.name,
    this.description,
    this.category,
    this.isPublic = true,
    this.createdByEmployeeId,
    required this.queryConfig,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'isPublic': isPublic,
      if (createdByEmployeeId != null) 'createdByEmployeeId': createdByEmployeeId,
      'queryConfig': queryConfig.toJson(),
    };
  }

  factory QueryTemplate.fromJson(Map<String, dynamic> json) {
    return QueryTemplate(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String? ?? 'Untitled Report',
      description: json['description'] as String?,
      category: json['category'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      createdByEmployeeId: (json['createdByEmployeeId'] as num?)?.toInt(),
      queryConfig: json['queryConfig'] != null
          ? QueryRequest.fromJson(json['queryConfig'] as Map<String, dynamic>)
          : const QueryRequest(
              rootEntity: 'EMPLOYEE',
              selectedFields: [],
              filterGroup: FilterGroup(),
            ),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }
}
