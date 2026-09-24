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
          badgeText: '12 DAYS / YEAR',
          badgeColor: const Color(0xFF3B82F6),
          icon: Icons.flight_takeoff_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: 'Casual Leave (CL)',
          description: 'For personal commitments, family events, urgent personal matters, or short leisure trips.',
          bullets: [
            'Accrual: Credited quarterly (3.0 days at the start of each calendar quarter: Jan, Apr, Jul, Oct).',
            'Notice: Requires a minimum of 2 working days prior application via the portal.',
            'Lapse: Unused Casual Leaves lapse on December 31st each year (No carry forward).',
            'Max Stretch: Can be taken for up to 3 consecutive days at a time.',
          ],
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: '10 DAYS / YEAR',
          badgeColor: const Color(0xFF10B981),
          icon: Icons.medical_services_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Sick / Medical Leave (SL)',
          description: 'Intended for recovery from illness, medical consultations, or health emergencies.',
          bullets: [
            'Accrual: Full 10.0 days credited upfront on January 1st of every calendar year.',
            'Notice: Apply within 24 hours of absence or resumption of duty.',
            'Medical Certificate: Mandatory doctor\'s fitness certificate for absences exceeding 2 consecutive days.',
            'Lapse: Non-encashable; maximum 5 days can carry forward to the subsequent year.',
          ],
        ),
        const SizedBox(height: 16),

        _buildPolicyCard(
          t,
          badgeText: '15 DAYS / YEAR',
          badgeColor: const Color(0xFF8B5CF6),
          icon: Icons.stars_rounded,
          iconColor: const Color(0xFF8B5CF6),
          title: 'Earned / Privilege Leave (EL)',
          description: 'Earned through continuous service, designed for planned vacations, holidays, and extended breaks.',
          bullets: [
            'Accrual: Accrued monthly at the rate of 1.25 days per completed month of active service.',
            'Notice: Requires minimum 14 calendar days prior approval from direct manager.',
            'Carry Forward: Up to 30 days can be accumulated and carried forward into future years.',
            'Encashment: Eligible for encashment upon separation or annual encashment window.',
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
              _buildMetricRow(t, 'Standard Shift Timing', '9:30 AM — 6:30 PM (Mon - Fri)'),
              _buildMetricRow(t, 'Total Duration', '9.0 Hours (Includes 1.0 Hour break)'),
              _buildMetricRow(t, 'Minimum Effective Hours', '8.0 Hours required for Full Day'),
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
          title: 'Punch-In Grace Period',
          description: 'A 15-minute buffer is allowed in the morning to accommodate commute delays.',
          bullets: [
            'Check-In before 9:45 AM: Considered ON TIME, no deduction or penalty.',
            'Check-In between 9:45 AM — 10:15 AM: Marked as LATE ARRIVAL.',
            'Monthly Late Buffer: Up to 3 late arrivals are excused per calendar month.',
            '4th Late Arrival onwards: Automatically results in 0.5 day Casual Leave / LOP deduction.',
            'Check-In after 11:30 AM: Treated as Half-Day automatically unless prior permission exists.',
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
            'Lunch Break: 1:00 PM — 2:00 PM (45 to 60 minutes).',
            'Tea / Coffee Break: Two 15-minute refreshment breaks (Morning: 11:30 AM, Evening: 4:30 PM).',
            'Extended breaks exceeding 1.5 hours total must be communicated to the team lead.',
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
            'Departure before 5:00 PM: Requires manager approval or counts as Half-Day.',
            'Worked 4.0 Hours to 7.0 Hours: Marked as HALF-DAY (0.5 Day attendance).',
            'Worked Less than 4.0 Hours: Marked as ABSENT / LOSS OF PAY (LOP).',
            'Emergency exits require an immediate punch-out and verbal/chat alert to HR.',
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
              Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: t.textSecondary),
          ),
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
    );
  }
}
