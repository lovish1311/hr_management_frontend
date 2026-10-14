import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import '../../data/models/query_ast.dart';
import '../../data/models/query_template.dart';

class ReportGalleryCard extends StatelessWidget {
  final ValueChanged<QueryTemplate> onSelectTemplate;

  const ReportGalleryCard({
    super.key,
    required this.onSelectTemplate,
  });

  static const List<QueryTemplate> defaultTemplates = [
    QueryTemplate(
      name: 'Active Staff Directory',
      description: 'Active employees across all departments with designations and joining dates',
      category: 'EMPLOYEE',
      queryConfig: QueryRequest(
        rootEntity: 'EMPLOYEE',
        selectedFields: ['employee.code', 'employee.fullName', 'employee.department', 'employee.designation', 'employee.status', 'employee.joiningDate'],
        filterGroup: FilterGroup(
          rules: [
            FilterRule(fieldId: 'employee.status', operator: 'EQUALS', values: ['ACTIVE']),
          ],
        ),
      ),
    ),
    QueryTemplate(
      name: 'Monthly Payroll Register',
      description: 'Total gross earnings, EPF/ESI statutory deductions, and net salary payout',
      category: 'PAYROLL',
      queryConfig: QueryRequest(
        rootEntity: 'PAYROLL',
        selectedFields: ['employee.code', 'employee.fullName', 'payroll.payrollMonth', 'payroll.totalGrossEarnings', 'payroll.deductionEpf', 'payroll.deductionEsi', 'payroll.totalDeductions', 'payroll.netTakeHome'],
        filterGroup: FilterGroup(),
      ),
    ),
    QueryTemplate(
      name: 'Approved Leave Encashment Audit',
      description: 'Approved leaves by department with total days and duration ranges',
      category: 'LEAVES',
      queryConfig: QueryRequest(
        rootEntity: 'LEAVES',
        selectedFields: ['employee.code', 'employee.fullName', 'leave.leaveType', 'leave.startDate', 'leave.endDate', 'leave.totalDays', 'leave.status'],
        filterGroup: FilterGroup(
          rules: [
            FilterRule(fieldId: 'leave.status', operator: 'EQUALS', values: ['APPROVED']),
          ],
        ),
      ),
    ),
    QueryTemplate(
      name: 'Attendance Working Hours Audit',
      description: 'Daily swipe analysis, working minutes, and attendance statuses',
      category: 'ATTENDANCE',
      queryConfig: QueryRequest(
        rootEntity: 'ATTENDANCE',
        selectedFields: ['employee.code', 'employee.fullName', 'attendance.date', 'attendance.status', 'attendance.totalWorkingMinutes'],
        filterGroup: FilterGroup(),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Pre-Built Enterprise Reports',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '1-Click quick launch pre-configured templates for common audits and payroll runs.',
          style: TextStyle(fontSize: 11, color: t.textSecondary),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: defaultTemplates.map((tmpl) {
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: t.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tmpl.category ?? 'REPORT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: t.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: t.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tmpl.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: t.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tmpl.description ?? '',
                      style: TextStyle(fontSize: 10, color: t.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          side: BorderSide(color: t.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => onSelectTemplate(tmpl),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Load Template',
                            style: TextStyle(fontSize: 11, color: t.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
