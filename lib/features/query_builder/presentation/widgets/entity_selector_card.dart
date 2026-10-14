import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import '../../data/models/query_metadata.dart';

class EntitySelectorCard extends StatelessWidget {
  final List<EntityMetadata> entities;
  final String selectedEntityId;
  final ValueChanged<String> onSelectEntity;

  const EntitySelectorCard({
    super.key,
    required this.entities,
    required this.selectedEntityId,
    required this.onSelectEntity,
  });

  IconData _getEntityIcon(String id) {
    switch (id.toUpperCase()) {
      case 'EMPLOYEE':
        return Icons.people_alt_rounded;
      case 'ATTENDANCE':
        return Icons.access_time_filled_rounded;
      case 'LEAVES':
        return Icons.beach_access_rounded;
      case 'PAYROLL':
        return Icons.payments_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.hub_rounded, size: 18, color: t.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Select Primary Domain',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Base entity defines the primary SQL table and available join relationships.',
          style: TextStyle(fontSize: 12, color: t.textSecondary),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 450;
            final isUltraNarrow = constraints.maxWidth < 350;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isNarrow ? 2 : 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: isUltraNarrow ? 1.05 : (isNarrow ? 1.2 : 1.4),
              ),
              itemCount: entities.length,
              itemBuilder: (context, index) {
                final entity = entities[index];
                final isSelected = entity.entityId.toUpperCase() == selectedEntityId.toUpperCase();

                return InkWell(
                  onTap: () => onSelectEntity(entity.entityId),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? t.primary.withValues(alpha: 0.1) : t.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? t.primary : t.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: t.primary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected ? t.primary : t.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getEntityIcon(entity.entityId),
                                size: 16,
                                color: isSelected ? Colors.white : t.primary,
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, size: 16, color: t.primary),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  entity.displayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? t.primary : t.text,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${entity.fields.length} available fields',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: t.textSecondary,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
