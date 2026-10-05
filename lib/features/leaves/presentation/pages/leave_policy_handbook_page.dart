import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/hr_drawer.dart';

class LeavePolicyHandbookPage extends StatefulWidget {
  const LeavePolicyHandbookPage({super.key});

  @override
  State<LeavePolicyHandbookPage> createState() => _LeavePolicyHandbookPageState();
}

class _LeavePolicyHandbookPageState extends State<LeavePolicyHandbookPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: const HrDrawer(),
      appBar: AppBar(
        title: Text(
          'Leave & Attendance Policy',
          style: TextStyle(
            color: t.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: t.card,
        elevation: 0,
        iconTheme: IconThemeData(color: t.text),
        bottom: TabBar(
          controller: _tabController,
          labelColor: t.primary,
          unselectedLabelColor: t.text.withValues(alpha: 0.6),
          indicatorColor: t.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.beach_access_rounded, size: 20), text: 'Leave Types & Quotas'),
            Tab(icon: Icon(Icons.access_time_filled_rounded, size: 20), text: 'Working Hours & Grace'),
            Tab(icon: Icon(Icons.coffee_rounded, size: 20), text: 'Breaks & Early Outs'),
            Tab(icon: Icon(Icons.rule_folder_rounded, size: 20), text: 'Regularization & Rules'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaveTypesTab(t, isDark),
          _buildWorkingHoursTab(t, isDark),
          _buildBreaksTab(t, isDark),
          _buildRegularizationTab(t, isDark),
        ],
      ),
    );
  }

  // ── Tab 1: Leave Types & Quotas ───────────────────────────────────────────
  Widget _buildLeaveTypesTab(AppThemeConfig t, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          t,
          icon: Icons.calendar_month_rounded,
          title: 'Annual Leave Entitlement',
          subtitle: 'Comprehensive guide to employee leave quotas, accrual cycles, and eligibility rules.',
        ),
        const SizedBox(height: 20),

        _buildPolicyCard(
          t,
          badgeText: '6 DAYS / YEAR',
          badgeColor: const Color(0xFF3B82F6),
          icon: Icons.flight_takeoff_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: 'Casual Leave (CL)',
          description: 'For personal commitments, family events, urgent personal matters, or short leisure trips.',
          bullets: [
            'Accrual: Standard 6.0 days credited quarterly (1.5 days/qtr) or 6.0 days upfront on Jan 1.',
            'Notice: Requires a minimum of 2 working days prior application via the portal.',
            'Lapse: Unused Casual Leaves lapse on December 31st each year (Strict zero carry forward / encashment).',
            'Max Stretch: Can be taken for up to 3 consecutive working days at a time.',
            'No Automatic Penalty: Late check-ins do NOT automatically deduct CL; regularization is HR-managed.',
          ],
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: '6 DAYS / YEAR',
          badgeColor: const Color(0xFF10B981),
          icon: Icons.medical_services_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Sick / Medical Leave (SL)',
          description: 'Intended for recovery from illness, medical consultations, or health emergencies.',
          bullets: [
            'Accrual: Full 6.0 days credited upfront on January 1st of every calendar year.',
            'Notice: Post-facto application allowed within 24 hours of absence or resumption of duty.',
            'Medical Certificate: Mandatory registered doctor\'s prescription/certificate for absences exceeding 2 consecutive days.',
            'Lapse: Non-encashable and zero carry forward; lapses on December 31st.',
          ],
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: '6 DAYS / YEAR',
          badgeColor: const Color(0xFF8B5CF6),
          icon: Icons.stars_rounded,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Earned / Privilege Leave (EL)',
          description: 'Earned through continuous service, designed for planned vacations, holidays, and extended breaks.',
          bullets: [
            'Accrual: Accrued continuously at 0.5 days per completed calendar month of active service (6.0 days/yr).',
            'Probation Rule: Strictly blocked during probation period (Accrual = 0.0).',
            'Notice: Requires minimum 14 calendar days advance submission via portal.',
            'Carry Forward & Encashment: Accumulative up to 6.0 days max; encashable upon employment separation.',
          ],
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: 'ACTIVE REMOTE DUTY',
          badgeColor: const Color(0xFF64748B),
          icon: Icons.home_work_rounded,
          iconColor: const Color(0xFF64748B),
          title: 'Work From Home (WFH / Remote Duty)',
          description: 'Remote execution of duties due to transit disruptions, emergencies, or home commitments.',
          bullets: [
            'Nature: Active duty status, NOT an absence. Attendance auto-marked as PRESENT (WFH).',
            'Quota Counter: Baseline starts at 0.0; display tracks as negative counters (-1, -2, -3...) when taken.',
            'Uncapped Applications: Applications are never blocked by quota limits.',
            'Salary Impact: Fully paid; zero impact on monthly salary.',
          ],
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: 'ADMIN GRANTED',
          badgeColor: const Color(0xFF059669),
          icon: Icons.card_giftcard_rounded,
          iconColor: const Color(0xFF059669),
          title: 'Compensatory Off (Comp-Off)',
          description: 'Time-off granted to compensate for overtime work on scheduled weekends or company holidays.',
          bullets: [
            'Grant Workflow: Verified and granted directly by HR/Admin in employee quota upon overtime duty.',
            'Application: Once credited, employee applies for time-off using their approved Comp-Off balance.',
            'Validity: Must be availed within 60 calendar days from the date of overtime work; otherwise expires.',
          ],
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: 'SPECIAL LEAVE',
          badgeColor: const Color(0xFFEC4899),
          icon: Icons.child_friendly_rounded,
          iconColor: const Color(0xFFEC4899),
          title: 'Maternity, Paternity & Bereavement Leave',
          description: 'Special leaves provided for critical life moments and family responsibilities.',
          bullets: [
            'Maternity Leave: 26 weeks paid leave for female employees as per statutory regulations.',
            'Paternity Leave: 5 working days paid leave for new fathers within 6 months of childbirth.',
            'Bereavement Leave: Up to 4 consecutive days paid leave in the unfortunate event of immediate family demise.',
          ],
        ),
      ],
    );
  }

  // ── Tab 2: Working Hours & Grace Period ───────────────────────────────────
  Widget _buildWorkingHoursTab(AppThemeConfig t, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          t,
          icon: Icons.schedule_rounded,
          title: 'Office Timings & Shifts',
          subtitle: 'Core operational hours, punch-in grace limits, and attendance calculation rules.',
        ),
        const SizedBox(height: 20),

        _buildInfoCard(
          t,
          title: 'Standard Working Hours',
          icon: Icons.business_center_rounded,
          iconColor: const Color(0xFFF59E0B),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricRow(t, 'Standard Shift Timing', '10:00 AM — 7:00 PM (Mon - Fri)'),
              _buildMetricRow(t, 'Lunch Break Window', '2:00 PM — 3:00 PM (1.0 Hour)'),
              _buildMetricRow(t, 'Total Duration', '9.0 Hours total shift duration'),
              _buildMetricRow(t, 'Minimum Effective Hours', '8.0 Hours for Full Day (4.0 - 7.9 for Half Day)'),
              _buildMetricRow(t, 'Weekly Offs', 'Saturday & Sunday'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: '15 MIN GRACE',
          badgeColor: const Color(0xFF10B981),
          icon: Icons.timer_outlined,
          iconColor: const Color(0xFF10B981),
          title: 'Punch-In Grace Buffer & Late Tracking',
          description: 'A 15-minute buffer (10:00 AM - 10:15 AM) accommodates commute delays.',
          bullets: [
            'Check-In on or before 10:15 AM: Counted as ON TIME, no deduction.',
            'Check-In after 10:15 AM: Flagged as LATE for attendance transparency.',
            'No Automated Penalties: The system does NOT automatically deduct Casual Leave or LOP for late arrivals.',
            'Discretionary Regularization: Any disciplinary penalty or regularization is executed exclusively by HR via Admin Portal.',
            'Intra-Day Late Permission: Pre-approved late check-ins allowed up to 2 hours (arrival between 10:15 AM and 12:00 PM).',
          ],
        ),
      ],
    );
  }

  // ── Tab 3: Breaks & Early Outs ────────────────────────────────────────────
  Widget _buildBreaksTab(AppThemeConfig t, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          t,
          icon: Icons.free_breakfast_rounded,
          title: 'Break Windows & Early Out Guidelines',
          subtitle: 'Permitted lunch and refreshment windows, early check-out policies, and half-day thresholds.',
        ),
        const SizedBox(height: 20),

        _buildPolicyCard(
          t,
          badgeText: 'DAILY SCHEDULE',
          badgeColor: const Color(0xFF3B82F6),
          icon: Icons.restaurant_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: 'Permitted Break Windows',
          description: 'Employees are encouraged to take structured breaks to recharge during the workday.',
          bullets: [
            'Lunch Break Window: 2:00 PM — 3:00 PM (1.0 Hour mandatory break).',
            'Short Break Permission: Intra-day personal/medical errand passes up to 2.0 hours maximum.',
            'No Automatic Deductions: Short breaks do not automatically incur leave or salary deductions; logged for audit.',
            'Refreshments: Coffee & tea available throughout the shift.',
          ],
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: 'EARLY CHECK-OUT',
          badgeColor: const Color(0xFFEF4444),
          icon: Icons.logout_rounded,
          iconColor: const Color(0xFFEF4444),
          title: 'Early Departure & Half-Day Rules',
          description: 'Calculations for partial working days and unscheduled early exits.',
          bullets: [
            'Early Out Permission: Permitted departure up to 2 hours prior to shift end (departure after 5:00 PM).',
            'Effective 8.0+ Hours: Marked as PRESENT (Full working day satisfied).',
            'Effective 4.0 to 7.9 Hours: Marked as HALF_DAY (0.5 Day attendance).',
            'Less than 4.0 Hours: Marked as ABSENT / UNEXCUSED_ABSENT if no approved leave exists.',
            'Zero Automatic Penalty: System logs early departures for HR review without automatic CL or LOP cuts.',
          ],
        ),
      ],
    );
  }

  // ── Tab 4: Regularization & Protocols ─────────────────────────────────────
  Widget _buildRegularizationTab(AppThemeConfig t, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeroBanner(
          t,
          icon: Icons.checklist_rtl_rounded,
          title: 'Regularization & Compliance',
          subtitle: 'Procedures for correcting missing biometric punches, on-duty approvals, and payroll cutoffs.',
        ),
        const SizedBox(height: 20),

        _buildPolicyCard(
          t,
          badgeText: 'MAX 2 PER MONTH',
          badgeColor: const Color(0xFFF59E0B),
          icon: Icons.fingerprint_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Missing Punch Regularization',
          description: 'In case of biometric device errors, client on-duty visits, or forgotten punches.',
          bullets: [
            'Submission Deadline: Must be submitted through the portal within 48 hours of the occurrence.',
            'Monthly Limit: Maximum 2 attendance regularizations permitted per employee each month.',
            'Approval Hierarchy: Automatically routes to Direct Manager -> HR for sign-off.',
            'Unregularized missing punches will be treated as Half-Day / LOP on monthly cutoff.',
          ],
        ),
        const SizedBox(height: 16),

        _buildInfoCard(
          t,
          title: 'Monthly Payroll Cutoff Dates',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF10B981),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricRow(t, 'Attendance Cutoff Date', '25th of every month'),
              _buildMetricRow(t, 'Leave Application Cutoff', '24th of every month (6:00 PM)'),
              _buildMetricRow(t, 'Payslip Release Date', 'Last working day of the month'),
              _buildMetricRow(t, 'Salary Disbursement', '1st of the following month'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helper UI Components ──────────────────────────────────────────────────
  Widget _buildHeroBanner(
    AppThemeConfig t, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(
    AppThemeConfig t, {
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> bullets,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: t.text.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          color: t.text.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    AppThemeConfig t, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: t.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildMetricRow(AppThemeConfig t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text),
            ),
          ),
        ],
      ),
    );
  }
}
