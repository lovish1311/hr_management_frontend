import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import '../../data/models/query_ast.dart';

class KpiMetricsBanner extends StatelessWidget {
  final KpiSummary? kpiSummary;
  final int totalMatchingRecords;
  final int executionTimeMs;

  const KpiMetricsBanner({
    super.key,
    this.kpiSummary,
    required this.totalMatchingRecords,
    this.executionTimeMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final metrics = [
            _MetricItem(
              icon: Icons.filter_list_rounded,
              label: 'Matched Records',
              value: '$totalMatchingRecords',
              color: t.primary,
            ),
            if (kpiSummary?.sumNetTakeHome != null)
              _MetricItem(
                icon: Icons.currency_rupee_rounded,
                label: 'Total Net Payout',
                value: '₹ ${_formatCurrency(kpiSummary!.sumNetTakeHome!)}',
                color: Colors.teal,
              ),
            if (kpiSummary?.sumGrossEarnings != null)
              _MetricItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Gross Earnings',
                value: '₹ ${_formatCurrency(kpiSummary!.sumGrossEarnings!)}',
                color: Colors.indigo,
              ),
            if (kpiSummary?.totalLopDays != null && kpiSummary!.totalLopDays! > 0)
              _MetricItem(
                icon: Icons.event_busy_rounded,
                label: 'Total LOP Days',
                value: '${kpiSummary!.totalLopDays!.toStringAsFixed(1)} d',
                color: Colors.orange,
              ),
            _MetricItem(
              icon: Icons.speed_rounded,
              label: 'Query Latency',
              value: '${executionTimeMs}ms',
              color: Colors.blueGrey,
            ),
          ];

          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (int i = 0; i < metrics.length; i++) ...[
                    metrics[i],
                    if (i < metrics.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(width: 1, height: 28, color: t.border),
                      ),
                  ],
                ],
              ),
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i < metrics.length - 1)
                  Container(width: 1, height: 32, color: t.border),
              ],
            ],
          );
        },
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)} Lakh';
    }
    return amount.toStringAsFixed(2);
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
