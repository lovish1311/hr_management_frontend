import 'package:flutter/material.dart';

class LeaveRequestTile extends StatelessWidget {
  final String employeeName;
  final String dates;
  final String reason;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const LeaveRequestTile({
    Key? key,
    required this.employeeName,
    required this.dates,
    required this.reason,
    this.onApprove,
    this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final borderColor = theme.dividerColor;
    final primaryTextColor = theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurfaceVariant;
    final primaryAccent = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    final nameInitials = employeeName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase();
    final isDark = theme.brightness == Brightness.dark;

    Color getAvatarColor(String name) {
      final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
      final colors = [
        Colors.teal,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
        Colors.orange,
        Colors.pink,
      ];
      return colors[hash % colors.length];
    }

    final avatarColor = getAvatarColor(employeeName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    nameInitials.isNotEmpty ? nameInitials : '?',
                    style: TextStyle(
                      color: avatarColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        employeeName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dates • $reason',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: onDecline,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                child: const Text(
                  'Decline',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: onPrimaryColor,
                  minimumSize: const Size(70, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: onApprove,
                child: const Text('Approve', style: TextStyle(fontSize: 13)),
              ),
            ],
          )
        ],
      ),
    );
  }
}