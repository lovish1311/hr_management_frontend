import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import '../../data/models/query_metadata.dart';

class FieldTransferList extends StatelessWidget {
  final MetadataCatalog catalog;
  final String activeEntityId;
  final List<String> selectedFieldIds;
  final ValueChanged<String> onToggleField;
  final void Function(int oldIndex, int newIndex) onReorderFields;

  const FieldTransferList({
    super.key,
    required this.catalog,
    required this.activeEntityId,
    required this.selectedFieldIds,
    required this.onToggleField,
    required this.onReorderFields,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final List<EntityMetadata> allEntities;
    if (activeEntityId.toUpperCase() == 'EMPLOYEE') {
      allEntities = catalog.entities;
    } else {
      final activeEnt = catalog.findEntity(activeEntityId);
      final empEnt = catalog.findEntity('EMPLOYEE');
      allEntities = [
        if (activeEnt != null) activeEnt,
        if (empEnt != null && empEnt != activeEnt) empEnt,
      ];
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvailableFieldsSection(context, t, allEntities),
              const SizedBox(height: 16),
              _buildSelectedFieldsSection(context, t),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildAvailableFieldsSection(context, t, allEntities),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 4,
              child: _buildSelectedFieldsSection(context, t),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvailableFieldsSection(
    BuildContext context,
    dynamic t,
    List<EntityMetadata> entities,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Available Columns',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: t.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Click to Add',
                    style: TextStyle(fontSize: 10, color: t.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final entity in entities) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: entity.entityId == activeEntityId ? t.primary : t.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entity.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: entity.entityId == activeEntityId ? t.primary : t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entity.fields.map((field) {
                final isSelected = selectedFieldIds.contains(field.fieldId);
                return FilterChip(
                  label: Text(field.label),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? t.primary : t.text,
                  ),
                  selected: isSelected,
                  selectedColor: t.primary.withValues(alpha: 0.15),
                  checkmarkColor: t.primary,
                  backgroundColor: t.cardSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? t.primary : t.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  onSelected: (_) => onToggleField(field.fieldId),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedFieldsSection(BuildContext context, dynamic t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Selected Columns (${selectedFieldIds.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: t.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Drag to Reorder',
                  style: TextStyle(fontSize: 10, color: t.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (selectedFieldIds.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_column_outlined, size: 32, color: t.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(height: 8),
                  Text(
                    'No columns selected yet',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.surfaceText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click any available column chip to include it in the report.',
                    style: TextStyle(fontSize: 11, color: t.surfaceTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedFieldIds.length,
              // ignore: deprecated_member_use
              onReorder: onReorderFields,
              itemBuilder: (context, index) {
                final fieldId = selectedFieldIds[index];
                final fieldMeta = catalog.findField(fieldId);
                final label = fieldMeta?.label ?? fieldId;

              return Container(
                key: ValueKey(fieldId),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: t.cardSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator_rounded, size: 16, color: t.textSecondary),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: t.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                      color: Colors.redAccent,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onToggleField(fieldId),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
