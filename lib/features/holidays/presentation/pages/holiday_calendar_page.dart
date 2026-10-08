import 'package:flutter/material.dart';
import 'package:hr_management/core/services/auth_storage.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import '../../data/models/holiday_model.dart';
import '../../data/services/holiday_service.dart';
import 'holiday_management_page.dart';

class HolidayCalendarPage extends StatefulWidget {
  const HolidayCalendarPage({super.key});

  @override
  State<HolidayCalendarPage> createState() => _HolidayCalendarPageState();
}

class _HolidayCalendarPageState extends State<HolidayCalendarPage> {
  int _selectedYear = DateTime.now().year;
  final List<int> _availableYears = [
    DateTime.now().year - 1,
    DateTime.now().year,
    DateTime.now().year + 1,
  ];

  EmployeeHolidayCalendarModel? _calendarData;
  bool _isLoading = true;
  String? _errorMessage;
  String _typeFilter = 'ALL'; // ALL, GENERAL, RESTRICTED

  @override
  void initState() {
    super.initState();
    _fetchCalendar();
  }

  Future<void> _fetchCalendar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await HolidayService.getEmployeeHolidayCalendar(_selectedYear);
      if (!mounted) return;
      setState(() {
        _calendarData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  Future<void> _applyForRestrictedHoliday(HolidayModel holiday) async {
    final t = context.appTheme;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: t.card,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.celebration_rounded, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Apply for Restricted Holiday',
                style: TextStyle(fontWeight: FontWeight.w800, color: t.text, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              holiday.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: t.primary),
            ),
            const SizedBox(height: 4),
            Text(
              "${holiday.date.day} ${_monthName(holiday.date.month)} ${holiday.date.year} • 1 Day",
              style: TextStyle(fontSize: 13, color: t.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.cardSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your application will be routed to your reporting manager for approval.',
                      style: TextStyle(fontSize: 12, color: t.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Reason / Remarks (Optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
            const SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(color: t.text),
              decoration: InputDecoration(
                hintText: 'e.g. Festival celebration with family',
                hintStyle: TextStyle(fontSize: 13, color: t.textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: t.cardSoft,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: t.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Apply', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await HolidayService.applyForRestrictedHoliday(
          holiday: holiday,
          reason: reasonController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Applied for '${holiday.name}'! Request sent to manager."),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _fetchCalendar();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '').trim()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isHrOrAdmin = AuthStorage.isHr || AuthStorage.isSuperAdmin;

    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Company Holidays', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: t.onBackgroundText)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: t.onBackgroundText),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: t.onBackgroundText),
            tooltip: 'Refresh Calendar',
            onPressed: _fetchCalendar,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls & Year Selection
            _buildHeader(t, isHrOrAdmin),
            const SizedBox(height: 24),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: CircularProgressIndicator(color: t.primary),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorBanner(t)
            else if (_calendarData == null || _calendarData!.holidays.isEmpty)
              _buildEmptyState(t, isHrOrAdmin)
            else ...[
              // Allowance Banner for Restricted Holidays
              _buildAllowanceBanner(t),
              const SizedBox(height: 24),

              // Filter Tabs
              _buildFilterBar(t),
              const SizedBox(height: 16),

              // Holiday List Cards
              _buildHolidayList(t),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeConfig t, bool isHrOrAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {

        final yearSelector = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, color: t.primary, size: 18),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  dropdownColor: t.card,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: t.text),
                  items: _availableYears.map((y) {
                    return DropdownMenuItem<int>(value: y, child: Text('Year $y'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && val != _selectedYear) {
                      setState(() => _selectedYear = val);
                      _fetchCalendar();
                    }
                  },
                ),
              ),
            ],
          ),
          ),
        );

        final adminButton = isHrOrAdmin
            ? ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/holiday_management').then((_) => _fetchCalendar());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.settings_suggest_rounded, size: 20),
                label: const Text('Manage Holidays', style: TextStyle(fontWeight: FontWeight.w700)),
              )
            : const SizedBox.shrink();

        return Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Holiday Calendar',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: t.onBackgroundText),
                ),
                yearSelector,
              ],
            ),
            adminButton,
          ],
        );
      },
    );
  }

  Widget _buildAllowanceBanner(AppThemeConfig t) {
    final quota = _calendarData!.restrictedHolidayQuota;
    final used = _calendarData!.restrictedHolidayUsed;
    final remaining = _calendarData!.restrictedHolidayRemaining;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final isNarrow = constraints.maxWidth < (textScale > 1.2 ? 950 : 700);

          final stats = Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildAllowanceStat(t, 'Allowed', quota.toInt().toString(), t.primary),
              _buildAllowanceStat(t, 'Used / Pending', used.toInt().toString(), const Color(0xFFD97706)),
              _buildAllowanceStat(t, 'Remaining', remaining.toInt().toString(), const Color(0xFF10B981)),
            ],
          );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const Icon(Icons.event_available_rounded, size: 20, color: Color(0xFFD97706)),
                  Text(
                    'Restricted Holidays (RH) Policy',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: t.text),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'You may select up to ${quota.toInt()} optional festival holidays from the restricted list each year.',
                style: TextStyle(fontSize: 13, color: t.textSecondary),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 16),
                stats,
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: info),
                const SizedBox(width: 20),
                stats,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildAllowanceStat(AppThemeConfig t, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppThemeConfig t) {
    final holidays = _calendarData!.holidays;
    final generalCount = holidays.where((h) => h.isGeneral).length;
    final restrictedCount = holidays.where((h) => h.isRestricted).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterTab(t, 'ALL', 'All Holidays (${holidays.length})'),
          const SizedBox(width: 8),
          _buildFilterTab(t, 'GENERAL', 'General ($generalCount)'),
          const SizedBox(width: 8),
          _buildFilterTab(t, 'RESTRICTED', 'Restricted ($restrictedCount)'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(AppThemeConfig t, String key, String label) {
    final isSelected = _typeFilter == key;
    return InkWell(
      onTap: () => setState(() => _typeFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? t.primary : t.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? t.primary : t.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : t.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHolidayList(AppThemeConfig t) {
    final holidays = _calendarData!.holidays;
    final filtered = holidays.where((h) {
      if (_typeFilter == 'GENERAL') return h.isGeneral;
      if (_typeFilter == 'RESTRICTED') return h.isRestricted;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Column(
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: t.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No holidays found for this category',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
        itemBuilder: (context, index) {
          final h = filtered[index];
          return _buildHolidayRow(t, h);
        },
      ),
    );
  }

  Widget _buildHolidayRow(AppThemeConfig t, HolidayModel holiday) {
    final isGeneral = holiday.isGeneral;
    final badgeColor = isGeneral ? const Color(0xFF10B981) : const Color(0xFFD97706);
    final weekday = _weekdayName(holiday.date.weekday);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          final isNarrow = constraints.maxWidth < (textScale > 1.2 ? 950 : 700);

          final dateBadge = Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  Text(
                    holiday.date.day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                    ),
                  ),
                  Text(
                    _monthName(holiday.date.month),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    holiday.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: t.text,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isGeneral ? 'General Holiday' : 'Restricted Holiday',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: t.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                        '$weekday • ${holiday.date.year}',
                        style: TextStyle(fontSize: 12, color: t.textSecondary),
                      ),
                      ],
                    ),
                  ),
                  if (holiday.description != null && holiday.description!.isNotEmpty)
                    Text(
                      '• ${holiday.description!}',
                      style: TextStyle(fontSize: 12, color: t.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          );
          final statusBadge = _buildActionOrStatusBadge(t, holiday);

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dateBadge,
                    const SizedBox(width: 14),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: statusBadge,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              dateBadge,
              const SizedBox(width: 16),
              Expanded(child: details),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: statusBadge,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionOrStatusBadge(AppThemeConfig t, HolidayModel holiday) {
    if (holiday.isGeneral) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration_rounded, size: 16, color: Color(0xFF10B981)),
            SizedBox(width: 6),
            Text(
              'Holiday',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    // Restricted Holiday status
    final status = holiday.status ?? 'NOT_APPLIED';
    final remaining = _calendarData?.restrictedHolidayRemaining ?? 0.0;

    if (status == 'PENDING') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.shade400),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 14, color: Colors.amber.shade900),
            const SizedBox(width: 6),
            Text('Pending Approval',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber.shade900)),
          ],
        ),
      );
    } else if (status == 'APPROVED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
            SizedBox(width: 6),
            Text('Approved',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
          ],
        ),
      );
    } else if (status == 'REJECTED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, size: 14, color: Colors.red),
            SizedBox(width: 6),
            Text('Rejected',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red)),
          ],
        ),
      );
    } else {
      // NOT_APPLIED -> Can apply
      final hasQuota = remaining > 0;
      return ElevatedButton.icon(
        onPressed: hasQuota ? () => _applyForRestrictedHoliday(holiday) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: t.textSecondary.withValues(alpha: 0.12),
          disabledForegroundColor: t.textSecondary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: hasQuota ? 1 : 0,
        ),
        icon: const Icon(Icons.add_task_rounded, size: 16),
        label: Text(
          hasQuota ? 'Apply' : 'Quota Full',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      );
    }
  }

  Widget _buildEmptyState(AppThemeConfig t, bool isHrOrAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.beach_access_rounded, size: 48, color: t.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No Published Holidays for $_selectedYear',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: t.text),
          ),
          const SizedBox(height: 8),
          Text(
            isHrOrAdmin
                ? 'You have not yet published the $_selectedYear holiday list for employees.'
                : 'The official holiday calendar for $_selectedYear has not been published by HR yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: t.textSecondary),
          ),
          if (isHrOrAdmin) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HolidayManagementPage()),
                ).then((_) => _fetchCalendar());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open Holiday Management', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(AppThemeConfig t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: _fetchCalendar,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  String _weekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}
