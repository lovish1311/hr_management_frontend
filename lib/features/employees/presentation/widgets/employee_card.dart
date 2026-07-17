import 'package:flutter/material.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const EmployeeCard({
    Key? key,
    required this.employee,
    required this.onTap,
  }) : super(key: key);

  Color _getAvatarColor(String name) {
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.deepOrange,
    ];
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initials = employee.name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase();
    final avatarColor = _getAvatarColor(employee.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Menu Button at top right
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
                onPressed: () {},
                padding: const EdgeInsets.all(8.0),
                constraints: const BoxConstraints(), // Reduces padding
              ),
            ),
            // Avatar
            Expanded(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.isNotEmpty ? initials : '?',
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                employee.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Role
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                employee.role,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              margin: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                employee.status,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
