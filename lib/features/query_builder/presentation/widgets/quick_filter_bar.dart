import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

class QuickFilterBar extends StatelessWidget {
  final String? selectedDepartment;
  final String? selectedStatus;
  final String? selectedMonth;
  final bool showMonthFilter;
  final ValueChanged<String?> onDepartmentChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onMonthChanged;

  const QuickFilterBar({
    super.key,
    this.selectedDepartment,
    this.selectedStatus,
    this.selectedMonth,
    this.showMonthFilter = true,
    required this.onDepartmentChanged,
    required this.onStatusChanged,
    required this.onMonthChanged,
  });

  static const departments = ['Engineering', 'HR', 'Sales', 'Marketing', 'Finance', 'Operations', 'Product'];
  static const statuses = ['ACTIVE', 'PROBATION', 'ON_LEAVE', 'TERMINATED'];
  static const months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.cardSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border.withValues(alpha: 0.6)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 16, color: t.primary),
                const SizedBox(width: 4),
                Text(
                  'Quick Filters:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Department Dropdown Chip
            _FilterDropdownChip(
              icon: Icons.business_rounded,
              label: selectedDepartment ?? 'All Depts',
              isActive: selectedDepartment != null,
              items: departments,
              onSelected: onDepartmentChanged,
              onClear: () => onDepartmentChanged(null),
            ),
            const SizedBox(width: 8),

            // Status Dropdown Chip
            _FilterDropdownChip(
              icon: Icons.verified_user_rounded,
              label: selectedStatus != null ? _formatStatus(selectedStatus!) : 'All Statuses',
              isActive: selectedStatus != null,
              items: statuses,
              onSelected: onStatusChanged,
              onClear: () => onStatusChanged(null),
            ),

            // Month Dropdown Chip (only relevant when root entity is PAYROLL)
            if (showMonthFilter) ...[
              const SizedBox(width: 8),
              _FilterDropdownChip(
                icon: Icons.calendar_today_rounded,
                label: selectedMonth ?? 'All Months',
                isActive: selectedMonth != null,
                items: months,
                onSelected: onMonthChanged,
                onClear: () => onMonthChanged(null),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatStatus(String s) {
    switch (s) {
      case 'ACTIVE':
        return 'Active';
      case 'PROBATION':
        return 'Probation';
      case 'ON_LEAVE':
        return 'On Leave';
      case 'TERMINATED':
        return 'Terminated';
      default:
        return s;
    }
  }
}

class _FilterDropdownChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _FilterDropdownChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.items,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Theme(
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
        onSelected: onSelected,
        itemBuilder: (context) {
          return items.map((item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  color: t.text,
                  fontWeight: item == label ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? t.primary.withValues(alpha: 0.12) : t.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? t.primary : t.border,
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? t.primary : t.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? t.primary : t.text,
                ),
              ),
              const SizedBox(width: 4),
              if (isActive)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3, right: 1),
                    child: Icon(Icons.close_rounded, size: 14, color: t.primary),
                  ),
                )
              else
                Icon(Icons.arrow_drop_down_rounded, size: 16, color: t.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
