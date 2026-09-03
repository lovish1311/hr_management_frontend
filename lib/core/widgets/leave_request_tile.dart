import 'package:flutter/material.dart';

class LeaveRequestTile extends StatelessWidget {
  final String employeeName;
  final String dates;
  final String reason;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  const LeaveRequestTile({
    super.key,
    required this.employeeName,
    required this.dates,
    required this.reason,
    this.onApprove,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurfaceVariant;

    final nameInitials = employeeName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase();

    Color getAvatarColor(String name) {
      final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
      final colors = [
        const Color(0xFF0D9488),
        const Color(0xFF0284C7),
        const Color(0xFF6366F1),
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
        const Color(0xFFF59E0B),
      ];
      return colors[hash % colors.length];
    }

    final avatarColor = getAvatarColor(employeeName);

    // Infer leave category from reason string
    String leaveType = 'Annual Leave';
    Color tagColor = const Color(0xFF0284C7);
    if (reason.toLowerCase().contains('sick') || reason.toLowerCase().contains('doctor') || reason.toLowerCase().contains('medical')) {
      leaveType = 'Medical Leave';
      tagColor = const Color(0xFFEF4444);
    } else if (reason.toLowerCase().contains('vacation') || reason.toLowerCase().contains('trip')) {
      leaveType = 'Vacation';
      tagColor = const Color(0xFF10B981);
    } else if (reason.toLowerCase().contains('personal') || reason.toLowerCase().contains('family')) {
      leaveType = 'Personal';
      tagColor = const Color(0xFF8B5CF6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;

          final infoSection = Row(
            children: [
              // Avatar with ring badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [avatarColor.withValues(alpha: 0.2), avatarColor.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarColor.withValues(alpha: 0.4), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  nameInitials.isNotEmpty ? nameInitials : '?',
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            employeeName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: primaryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            leaveType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tagColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: secondaryTextColor),
                        const SizedBox(width: 4),
                        Text(
                          dates,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decline Button
              OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(36, 36),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: const Color(0xFFFEF2F2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                    SizedBox(width: 4),
                    Text(
                      'Decline',
                      style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Approve Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(36, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onApprove,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoSection,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: actionButtons,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: infoSection),
              const SizedBox(width: 12),
              actionButtons,
            ],
          );
        },
      ),
    );
  }
}