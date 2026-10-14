class MetadataCatalog {
  final List<EntityMetadata> entities;

  const MetadataCatalog({required this.entities});

  factory MetadataCatalog.fromJson(Map<String, dynamic> json) {
    return MetadataCatalog(
      entities: (json['entities'] as List<dynamic>? ?? [])
          .map((e) => EntityMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  EntityMetadata? findEntity(String entityId) {
    try {
      return entities.firstWhere((e) => e.entityId.toUpperCase() == entityId.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  FieldMetadata? findField(String fieldId) {
    for (final entity in entities) {
      for (final field in entity.fields) {
        if (field.fieldId == fieldId) return field;
      }
    }
    return null;
  }
}

class EntityMetadata {
  final String entityId;
  final String displayName;
  final String description;
  final List<FieldMetadata> fields;

  const EntityMetadata({
    required this.entityId,
    required this.displayName,
    required this.description,
    required this.fields,
  });

  factory EntityMetadata.fromJson(Map<String, dynamic> json) {
    return EntityMetadata(
      entityId: json['entityId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      fields: (json['fields'] as List<dynamic>? ?? [])
          .map((f) => FieldMetadata.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FieldMetadata {
  final String fieldId;
  final String label;
  final String dataType; // "STRING", "NUMBER", "DATE", "ENUM"
  final bool filterable;
  final bool projectable;
  final List<String> allowedOperators;
  final List<String> options;

  const FieldMetadata({
    required this.fieldId,
    required this.label,
    required this.dataType,
    this.filterable = true,
    this.projectable = true,
    this.allowedOperators = const [],
    this.options = const [],
  });

  factory FieldMetadata.fromJson(Map<String, dynamic> json) {
    return FieldMetadata(
      fieldId: json['fieldId'] as String? ?? '',
      label: json['label'] as String? ?? '',
      dataType: json['dataType'] as String? ?? 'STRING',
      filterable: json['filterable'] as bool? ?? true,
      projectable: json['projectable'] as bool? ?? true,
      allowedOperators: (json['allowedOperators'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
