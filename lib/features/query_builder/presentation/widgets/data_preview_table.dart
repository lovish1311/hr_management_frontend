import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import '../../data/models/query_ast.dart';

class DataPreviewTable extends StatelessWidget {
  final List<ColumnMeta> columns;
  final List<Map<String, dynamic>> rows;
  final String? sortBy;
  final String sortDirection;
  final ValueChanged<String> onSortChanged;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;
  final bool isLoading;

  const DataPreviewTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortBy,
    this.sortDirection = 'ASC',
    required this.onSortChanged,
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final totalPages = (totalCount / pageSize).ceil();

    if (isLoading && (columns.isEmpty || rows.isEmpty)) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: t.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Compiling AST and executing query...',
                style: TextStyle(fontSize: 12, color: t.surfaceTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (columns.isEmpty || rows.isEmpty) {
      return Container(
        height: 240,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.table_chart_outlined, size: 40, color: t.textSecondary),
              const SizedBox(height: 8),
              Text(
                'No preview records match the selected conditions',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.surfaceText),
              ),
              const SizedBox(height: 4),
              Text(
                'Try broadening your filter rules or selecting another root entity.',
                style: TextStyle(fontSize: 11, color: t.surfaceTextSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Loading Progress Bar if data is refreshing in background
          if (isLoading)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: LinearProgressIndicator(
                minHeight: 2.5,
                color: t.primary,
                backgroundColor: t.primary.withValues(alpha: 0.12),
              ),
            ),

          // Sticky Table Header & Scrollable 2D Table
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isLoading ? 0.65 : 1.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  t.isDarkTheme ? Colors.grey.shade900 : const Color(0xFF1E293B),
                ),
                dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
                  return null; // alternate via row indexing or let theme handle
                }),
                horizontalMargin: 14,
                columnSpacing: 20,
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                dataTextStyle: TextStyle(
                  color: t.text,
                  fontSize: 12,
                ),
                columns: columns.map((col) {
                  final isSorted = sortBy == col.fieldId;
                  return DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(col.label),
                        const SizedBox(width: 4),
                        if (isSorted)
                          Icon(
                            sortDirection == 'ASC'
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: Colors.amberAccent,
                          )
                        else
                          const Icon(Icons.unfold_more_rounded, size: 14, color: Colors.white54),
                      ],
                    ),
                    onSort: (_, __) => onSortChanged(col.fieldId),
                  );
                }).toList(),
                rows: rows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  final isEven = idx % 2 == 0;

                  return DataRow(
                    color: WidgetStateProperty.all(
                      isEven
                          ? (t.isDarkTheme ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC))
                          : t.card,
                    ),
                    cells: columns.map((col) {
                      final val = row[col.fieldId];
                      return DataCell(
                        Text(
                          _formatCellValue(val, col.dataType),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: col.dataType == 'NUMBER' ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: t.cardSoft,
              border: Border(top: BorderSide(color: t.border)),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Showing ${rows.length} of $totalCount (Page ${currentPage + 1}/${totalPages > 0 ? totalPages : 1})',
                        style: TextStyle(fontSize: 11, color: t.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, size: 20),
                            onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
                          ),
                          Text(
                            '${currentPage + 1}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.primary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, size: 20),
                            onPressed: (currentPage + 1) < totalPages
                                ? () => onPageChanged(currentPage + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Showing ${rows.length} of $totalCount matching records (Page ${currentPage + 1} of ${totalPages > 0 ? totalPages : 1})',
                        style: TextStyle(fontSize: 11, color: t.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 20),
                          onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
                        ),
                        Text(
                          '${currentPage + 1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: t.primary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 20),
                          onPressed: (currentPage + 1) < totalPages
                              ? () => onPageChanged(currentPage + 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCellValue(dynamic val, String dataType) {
    if (val == null) return '-';
    if (dataType == 'NUMBER' && val is num) {
      if (val.toString().contains('.') && val is double) {
        return val.toStringAsFixed(2);
      }
      return val.toString();
    }
    return val.toString();
  }
}
