import 'package:flutter/material.dart';

class TambolaBoardWidget extends StatelessWidget {
  final Set<int> drawnNumbers;
  final int? latestNumber;
  final bool compact;

  const TambolaBoardWidget({
    super.key,
    required this.drawnNumbers,
    this.latestNumber,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.grid_on_rounded, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'CALLER BOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${drawnNumbers.length}/90 Drawn',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Latest Drawn Number Spotlight (if available)
            if (latestNumber != null)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$latestNumber',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LATEST NUMBER CALLED',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Number $latestNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 1-90 Numbers Grid (10 columns, 9 rows) with increased height
            Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 9 * 4) / 10;
                  final itemHeight = itemWidth.clamp(32.0, 48.0);

                  return Column(
                    children: List.generate(9, (row) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: row < 8 ? 4.0 : 0.0),
                        child: Row(
                          children: List.generate(10, (col) {
                            final number = row * 10 + col + 1;
                            final isDrawn = drawnNumbers.contains(number);
                            final isLatest = (latestNumber == number);

                            return Expanded(
                              child: Container(
                                height: itemHeight,
                                margin: EdgeInsets.only(right: col < 9 ? 4.0 : 0.0),
                                decoration: BoxDecoration(
                                  gradient: isLatest
                                      ? const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                        )
                                      : isDrawn
                                          ? const LinearGradient(
                                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                                            )
                                          : null,
                                  color: !isDrawn
                                      ? (isDark
                                          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                                          : const Color(0xFFF1F5F9))
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isLatest
                                        ? const Color(0xFFFBBF24)
                                        : isDrawn
                                            ? const Color(0xFF047857)
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.08)
                                                : const Color(0xFFCBD5E1)),
                                    width: isLatest ? 2 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$number',
                                  style: TextStyle(
                                    fontSize: compact ? 11 : 14,
                                    fontWeight: isDrawn ? FontWeight.w900 : FontWeight.w600,
                                    color: isDrawn
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}
