import 'package:flutter/material.dart';
import '../../data/models/tambola_models.dart';

class TambolaTicketWidget extends StatefulWidget {
  final TambolaTicket ticket;
  final Set<int> drawnNumbers;
  final Set<int> markedNumbers;
  final ValueChanged<int> onNumberToggled;

  const TambolaTicketWidget({
    super.key,
    required this.ticket,
    required this.drawnNumbers,
    required this.markedNumbers,
    required this.onNumberToggled,
  });

  @override
  State<TambolaTicketWidget> createState() => _TambolaTicketWidgetState();
}

class _TambolaTicketWidgetState extends State<TambolaTicketWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ticket Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFFFBBF24), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OFFICIAL TAMBOLA TICKET',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Ticket #${widget.ticket.ticketId} • 15 Numbers',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Crossed Out Counter Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.markedNumbers.length}/15',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3x9 Matrix Body
            Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final colWidth = (constraints.maxWidth - 8 * 4) / 9;
                  final cellHeight = (colWidth * 1.05).clamp(32.0, 50.0);

                  return Column(
                    children: List.generate(3, (rowIndex) {
                      final rowList = (rowIndex < widget.ticket.grid.length)
                          ? widget.ticket.grid[rowIndex]
                          : List<int>.filled(9, 0);

                      return Padding(
                        padding: EdgeInsets.only(bottom: rowIndex < 2 ? 5.0 : 0.0),
                        child: Row(
                          children: List.generate(9, (colIndex) {
                            final number = (colIndex < rowList.length) ? rowList[colIndex] : 0;
                            return Expanded(
                              child: Container(
                                height: cellHeight,
                                margin: EdgeInsets.only(right: colIndex < 8 ? 4.0 : 0.0),
                                child: _buildCell(number, isDark),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            // Legend Footer (No hints!)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Tapped / Crossed',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Blank Cell',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int number, bool isDark) {
    if (number == 0) {
      // Empty blank cell
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      );
    }

    final isMarked = widget.markedNumbers.contains(number);

    return InkWell(
      onTap: () => widget.onNumberToggled(number),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          // Calm background even when marked - no garish solid orange box!
          color: isMarked
              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMarked
                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                : (isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1)),
            width: isMarked ? 1.5 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The number text - slightly grayish when marked
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isMarked
                    ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),

            // Authentic Cross (X) over the number when marked
            if (isMarked)
              const Icon(
                Icons.close_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
