import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import '../../data/models/query_ast.dart';
import '../../data/models/query_metadata.dart';

class VisualRuleBuilder extends StatelessWidget {
  final MetadataCatalog catalog;
  final String? rootEntity;
  final FilterGroup filterGroup;
  final ValueChanged<FilterGroup> onGroupChanged;
  final int maxDepth;
  final int currentDepth;

  const VisualRuleBuilder({
    super.key,
    required this.catalog,
    this.rootEntity,
    required this.filterGroup,
    required this.onGroupChanged,
    this.maxDepth = 3,
    this.currentDepth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentDepth == 1 ? t.card : t.cardSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentDepth == 1 ? t.border : t.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conjunction toggle & Group control
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: t.cardSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ConjunctionOption(
                        label: 'AND (All)',
                        isSelected: filterGroup.conjunction == 'AND',
                        onTap: () => onGroupChanged(filterGroup.copyWith(conjunction: 'AND')),
                      ),
                      _ConjunctionOption(
                        label: 'OR (Any)',
                        isSelected: filterGroup.conjunction == 'OR',
                        onTap: () => onGroupChanged(filterGroup.copyWith(conjunction: 'OR')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Add Rule', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: t.primary,
                  ),
                  onPressed: _addNewRule,
                ),
                if (currentDepth < maxDepth)
                  TextButton.icon(
                    icon: const Icon(Icons.playlist_add_rounded, size: 14),
                    label: const Text('Add Subgroup', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: t.textSecondary,
                    ),
                    onPressed: _addNewSubGroup,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Rules list
          if (filterGroup.rules.isEmpty && filterGroup.subGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No filter rules configured (all records matched). Click "Add Rule" to filter.',
                  style: TextStyle(fontSize: 12, color: t.textSecondary, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            for (int i = 0; i < filterGroup.rules.length; i++)
              _RuleRow(
                key: ValueKey('rule_${currentDepth}_$i'),
                catalog: catalog,
                rootEntity: rootEntity,
                rule: filterGroup.rules[i],
                onChanged: (updated) {
                  final newRules = List<FilterRule>.from(filterGroup.rules);
                  newRules[i] = updated;
                  onGroupChanged(filterGroup.copyWith(rules: newRules));
                },
                onDelete: () {
                  final newRules = List<FilterRule>.from(filterGroup.rules)..removeAt(i);
                  onGroupChanged(filterGroup.copyWith(rules: newRules));
                },
              ),

            // Nested subgroups
            for (int j = 0; j < filterGroup.subGroups.length; j++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: VisualRuleBuilder(
                        catalog: catalog,
                        rootEntity: rootEntity,
                        filterGroup: filterGroup.subGroups[j],
                        currentDepth: currentDepth + 1,
                        maxDepth: maxDepth,
                        onGroupChanged: (updatedSub) {
                          final newSubs = List<FilterGroup>.from(filterGroup.subGroups);
                          newSubs[j] = updatedSub;
                          onGroupChanged(filterGroup.copyWith(subGroups: newSubs));
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: Colors.redAccent,
                      padding: const EdgeInsets.only(left: 4, top: 12),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final newSubs = List<FilterGroup>.from(filterGroup.subGroups)..removeAt(j);
                        onGroupChanged(filterGroup.copyWith(subGroups: newSubs));
                      },
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _addNewRule() {
    final compatibleFields = _getCompatibleFields(catalog, rootEntity);
    String defaultField = compatibleFields.isNotEmpty ? compatibleFields.first.fieldId : 'employee.status';
    final fieldMeta = catalog.findField(defaultField);
    List<String> defaultValues = fieldMeta?.options.isNotEmpty == true ? [fieldMeta!.options.first] : [''];

    final newRules = List<FilterRule>.from(filterGroup.rules)
      ..add(FilterRule(
        fieldId: defaultField,
        operator: 'EQUALS',
        values: defaultValues,
      ));
    onGroupChanged(filterGroup.copyWith(rules: newRules));
  }

  static List<FieldMetadata> _getCompatibleFields(MetadataCatalog catalog, String? rootEntity) {
    if (rootEntity == null || rootEntity.toUpperCase() == 'EMPLOYEE') {
      return catalog.entities.expand((e) => e.fields).toList();
    }
    return catalog.entities
        .where((e) => e.entityId.toUpperCase() == rootEntity.toUpperCase() || e.entityId.toUpperCase() == 'EMPLOYEE')
        .expand((e) => e.fields)
        .toList();
  }

  void _addNewSubGroup() {
    final newSubs = List<FilterGroup>.from(filterGroup.subGroups)
      ..add(const FilterGroup(conjunction: 'AND'));
    onGroupChanged(filterGroup.copyWith(subGroups: newSubs));
  }
}

class _ConjunctionOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConjunctionOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? t.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : t.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatefulWidget {
  final MetadataCatalog catalog;
  final String? rootEntity;
  final FilterRule rule;
  final ValueChanged<FilterRule> onChanged;
  final VoidCallback onDelete;

  const _RuleRow({
    super.key,
    required this.catalog,
    this.rootEntity,
    required this.rule,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_RuleRow> createState() => _RuleRowState();
}

class _RuleRowState extends State<_RuleRow> {
  late TextEditingController _valController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _valController = TextEditingController(
      text: widget.rule.values.isNotEmpty ? widget.rule.values.first : '',
    );
  }

  @override
  void didUpdateWidget(covariant _RuleRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final curVal = widget.rule.values.isNotEmpty ? widget.rule.values.first : '';
    if (_valController.text != curVal) {
      _valController.value = TextEditingValue(
        text: curVal,
        selection: TextSelection.collapsed(offset: curVal.length),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _valController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final allFields = VisualRuleBuilder._getCompatibleFields(widget.catalog, widget.rootEntity);
    final fieldMeta = widget.catalog.findField(widget.rule.fieldId) ??
        (allFields.isNotEmpty ? allFields.first : null);

    final allowedOps = fieldMeta?.allowedOperators.isNotEmpty == true
        ? fieldMeta!.allowedOperators
        : ['EQUALS', 'NOT_EQUALS', 'CONTAINS', 'GREATER_THAN', 'LESS_THAN'];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: t.cardSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border.withValues(alpha: 0.7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 500;

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildFieldSelector(allFields, fieldMeta, t)),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: Colors.redAccent,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(flex: 4, child: _buildOperatorSelector(allowedOps, t)),
                    const SizedBox(width: 6),
                    Expanded(flex: 5, child: _buildValueInput(fieldMeta, t)),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 4, child: _buildFieldSelector(allFields, fieldMeta, t)),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: _buildOperatorSelector(allowedOps, t)),
              const SizedBox(width: 8),
              Expanded(flex: 4, child: _buildValueInput(fieldMeta, t)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: Colors.redAccent,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onDelete,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFieldSelector(List<FieldMetadata> allFields, FieldMetadata? current, dynamic t) {
    return DropdownButtonFormField<String>(
      initialValue: current?.fieldId,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      items: allFields.map((f) {
        return DropdownMenuItem<String>(
          value: f.fieldId,
          child: Text(f.label, style: TextStyle(fontSize: 12, color: t.text)),
        );
      }).toList(),
      onChanged: (newFieldId) {
        if (newFieldId != null) {
          final newMeta = widget.catalog.findField(newFieldId);
          final newOp = (newMeta != null && newMeta.allowedOperators.isNotEmpty)
              ? newMeta.allowedOperators.first
              : 'EQUALS';
          widget.onChanged(widget.rule.copyWith(
            fieldId: newFieldId,
            operator: newOp,
            values: newMeta?.options.isNotEmpty == true ? [newMeta!.options.first] : [''],
          ));
        }
      },
    );
  }

  Widget _buildOperatorSelector(List<String> allowedOps, dynamic t) {
    final validOp = allowedOps.contains(widget.rule.operator) ? widget.rule.operator : allowedOps.first;

    return DropdownButtonFormField<String>(
      initialValue: validOp,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      items: allowedOps.map((op) {
        return DropdownMenuItem<String>(
          value: op,
          child: Text(_formatOp(op), style: TextStyle(fontSize: 12, color: t.text)),
        );
      }).toList(),
      onChanged: (newOp) {
        if (newOp != null) {
          widget.onChanged(widget.rule.copyWith(operator: newOp));
        }
      },
    );
  }

  Widget _buildValueInput(FieldMetadata? fieldMeta, dynamic t) {
    if (fieldMeta != null && fieldMeta.options.isNotEmpty) {
      final currentVal = widget.rule.values.isNotEmpty ? widget.rule.values.first : fieldMeta.options.first;
      final selectedVal = fieldMeta.options.contains(currentVal) ? currentVal : fieldMeta.options.first;

      return DropdownButtonFormField<String>(
        initialValue: selectedVal,
        isExpanded: true,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        items: fieldMeta.options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt,
            child: Text(opt, style: TextStyle(fontSize: 12, color: t.text)),
          );
        }).toList(),
        onChanged: (newVal) {
          if (newVal != null) {
            widget.onChanged(widget.rule.copyWith(values: [newVal]));
          }
        },
      );
    }

    return TextField(
      controller: _valController,
      style: TextStyle(fontSize: 12, color: t.text),
      decoration: InputDecoration(
        isDense: true,
        hintText: fieldMeta?.dataType == 'NUMBER' ? 'e.g. 50000' : 'Filter value...',
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onChanged: (text) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          widget.onChanged(widget.rule.copyWith(values: [text]));
        });
      },
    );
  }

  String _formatOp(String op) {
    switch (op) {
      case 'EQUALS':
        return 'Equals (=)';
      case 'NOT_EQUALS':
        return 'Not Equals (!=)';
      case 'CONTAINS':
        return 'Contains';
      case 'STARTS_WITH':
        return 'Starts with';
      case 'ENDS_WITH':
        return 'Ends with';
      case 'GREATER_THAN':
        return 'Greater than (>)';
      case 'LESS_THAN':
        return 'Less than (<)';
      case 'BETWEEN':
        return 'Between';
      case 'IN':
        return 'In list';
      case 'BEFORE':
        return 'Before date';
      case 'AFTER':
        return 'After date';
      default:
        return op;
    }
  }
}
