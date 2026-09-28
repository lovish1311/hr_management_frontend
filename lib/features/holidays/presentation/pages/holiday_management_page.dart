import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';
import '../../data/models/holiday_model.dart';
import '../../data/services/holiday_service.dart';
import '../widgets/add_holiday_dialog.dart';

class HolidayManagementPage extends StatefulWidget {
  const HolidayManagementPage({super.key});

  @override
  State<HolidayManagementPage> createState() => _HolidayManagementPageState();
}

class _HolidayManagementPageState extends State<HolidayManagementPage> {
  int _selectedYear = DateTime.now().year;
  final List<int> _availableYears = [
    DateTime.now().year - 1,
    DateTime.now().year,
    DateTime.now().year + 1,
    DateTime.now().year + 2,
  ];

  HolidayListModel? _currentList;
  List<HolidayModel> _holidays = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _typeFilter = 'ALL'; // ALL, GENERAL, RESTRICTED

  @override
  void initState() {
    super.initState();
    _fetchHolidayList();
  }

  Future<void> _fetchHolidayList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lists = await HolidayService.getHolidayLists(_selectedYear);
      if (lists.isNotEmpty) {
        _currentList = lists.first;
        final details = await HolidayService.getHolidayListDetails(_currentList!.id!);
        _currentList = details;
        _holidays = details.holidays;
      } else {
        _currentList = null;
        _holidays = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createHolidayList() async {
    final t = context.appTheme;
    final nameController = TextEditingController(text: 'Official Holidays $_selectedYear');
    final descController = TextEditingController(text: 'Annual company calendar for $_selectedYear');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: t.card,
        title: Text('Create Holiday List for $_selectedYear',
            style: TextStyle(fontWeight: FontWeight.w800, color: t.text, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('List Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: TextStyle(color: t.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: t.cardSoft,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.border)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
            const SizedBox(height: 6),
            TextField(
              controller: descController,
              maxLines: 2,
              style: TextStyle(color: t.text),
              decoration: InputDecoration(
                filled: true,
                fillColor: t.cardSoft,
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
            onPressed: () async {
              try {
                await HolidayService.createHolidayList(
                  name: nameController.text.trim(),
                  year: _selectedYear,
                  description: descController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception:', ''))),
                  );
                }
              }
            },
            child: const Text('Create List', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (created == true) {
      _fetchHolidayList();
    }
  }

  Future<void> _togglePublish() async {
    if (_currentList == null) return;
    final newPublished = !_currentList!.published;

    try {
      await HolidayService.togglePublishHolidayList(_currentList!.id!, newPublished);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newPublished
                ? 'Holiday List published! Eligible employees can now view holidays.'
                : 'Holiday List unpublished (draft mode).'),
            backgroundColor: newPublished ? const Color(0xFF10B981) : Colors.amber.shade800,
          ),
        );
      }
      _fetchHolidayList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update publication: $e')),
        );
      }
    }
  }

  Future<void> _openAddHolidayDialog([HolidayModel? existing]) async {
    if (_currentList == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddHolidayDialog(
        holidayListId: _currentList!.id!,
        year: _selectedYear,
        existingHoliday: existing,
      ),
    );

    if (result == true) {
      _fetchHolidayList();
    }
  }

  Future<void> _switchHolidayType(HolidayModel holiday) async {
    final newType = holiday.isGeneral ? 'RESTRICTED' : 'GENERAL';
    try {
      await HolidayService.updateHoliday(id: holiday.id!, type: newType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Changed '${holiday.name}' to ${newType == 'GENERAL' ? 'General Holiday' : 'Restricted Holiday'}"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _fetchHolidayList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch type: $e')),
        );
      }
    }
  }

  Future<void> _deleteHoliday(HolidayModel holiday) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = context.appTheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: t.card,
          title: Text('Delete Holiday?', style: TextStyle(color: t.text, fontWeight: FontWeight.w800)),
          content: Text('Are you sure you want to delete "${holiday.name}" from the $_selectedYear holiday calendar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: t.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await HolidayService.deleteHoliday(holiday.id!);
        _fetchHolidayList();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete holiday: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;

    return ResponsiveScaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Holiday Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: t.onBackgroundText)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: t.onBackgroundText),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: t.onBackgroundText),
            tooltip: 'Refresh',
            onPressed: _fetchHolidayList,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls: Year Selector & Action Buttons
            _buildHeaderControls(t),
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
            else if (_currentList == null)
              _buildEmptyListState(t)
            else ...[
              // Stats Cards
              _buildStatsRow(t),
              const SizedBox(height: 24),

              // Filter Tabs
              _buildFilterBar(t),
              const SizedBox(height: 16),

              // Holiday Items Table/List
              _buildHolidayList(t),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderControls(AppThemeConfig t) {
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
              Icon(Icons.calendar_month_rounded, color: t.primary, size: 20),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  dropdownColor: t.card,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: t.text),
                  items: _availableYears.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text('Year $year'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && val != _selectedYear) {
                      setState(() => _selectedYear = val);
                      _fetchHolidayList();
                    }
                  },
                ),
              ),
            ],
          ),
          ),
        );

        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_currentList != null) ...[
              OutlinedButton.icon(
                onPressed: _togglePublish,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _currentList!.published ? Colors.amber.shade800 : const Color(0xFF10B981),
                  side: BorderSide(
                    color: _currentList!.published ? Colors.amber.shade800 : const Color(0xFF10B981),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  _currentList!.published ? Icons.visibility_off_rounded : Icons.publish_rounded,
                  size: 18,
                ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _currentList!.published ? 'Unpublish' : 'Publish List',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddHolidayDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Add Holiday', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _createHolidayList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.playlist_add_rounded, size: 20),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Create $_selectedYear Holiday List', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        );

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
                  'Annual Holidays',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: t.onBackgroundText,
                  ),
                ),
                yearSelector,
              ],
            ),
            actionButtons,
          ],
        );
      },
    );
  }

  Widget _buildStatsRow(AppThemeConfig t) {
    final generalCount = _holidays.where((h) => h.isGeneral).length;
    final restrictedCount = _holidays.where((h) => h.isRestricted).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 750;

        final items = [
          _buildStatCard(
            t: t,
            title: 'Total Holidays',
            count: '${_holidays.length}',
            subtitle: 'Configured for $_selectedYear',
            icon: Icons.event_note_rounded,
            color: t.primary,
          ),
          _buildStatCard(
            t: t,
            title: 'General Holidays',
            count: '$generalCount',
            subtitle: 'Mandatory paid days off',
            icon: Icons.celebration_rounded,
            color: const Color(0xFF10B981),
          ),
          _buildStatCard(
            t: t,
            title: 'Restricted Holidays',
            count: '$restrictedCount',
            subtitle: 'Optional festival leaves',
            icon: Icons.filter_vintage_rounded,
            color: const Color(0xFFD97706),
          ),
          _buildStatCard(
            t: t,
            title: 'Publish Status',
            count: _currentList!.published ? 'Published' : 'Draft',
            subtitle: _currentList!.published ? 'Visible to employees' : 'Hidden from employees',
            icon: _currentList!.published ? Icons.check_circle_rounded : Icons.edit_note_rounded,
            color: _currentList!.published ? const Color(0xFF10B981) : Colors.amber.shade800,
            isTextCount: true,
          ),
        ];

        if (isDesktop) {
          return Row(
            children: items.map((card) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: card))).toList(),
          );
        } else {
          return Column(
            children: items.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList(),
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required AppThemeConfig t,
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isTextCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.textSecondary)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: isTextCount ? 20 : 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: t.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppThemeConfig t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterTab(t, 'ALL', 'All Holidays (${_holidays.length})'),
          const SizedBox(width: 8),
          _buildFilterTab(t, 'GENERAL', 'General (${_holidays.where((h) => h.isGeneral).length})'),
          const SizedBox(width: 8),
          _buildFilterTab(t, 'RESTRICTED', 'Restricted (${_holidays.where((h) => h.isRestricted).length})'),
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
    final filtered = _holidays.where((h) {
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
            Icon(Icons.event_busy_rounded, size: 48, color: t.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No holidays found in this category',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
            const SizedBox(height: 6),
            Text('Click "Add Holiday" above to add dates to the $_selectedYear list',
                style: TextStyle(fontSize: 13, color: t.textSecondary)),
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
          final isNarrow = constraints.maxWidth < 620;

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
                  Row(
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
          final actionButtons = Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Tooltip(
                message: isGeneral ? 'Change to Restricted Holiday' : 'Change to General Holiday',
                child: TextButton.icon(
                  onPressed: () => _switchHolidayType(holiday),
                  style: TextButton.styleFrom(
                    foregroundColor: t.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  icon: Icon(Icons.swap_horiz_rounded, size: 16, color: t.primary),
                  label: Text(
                    isGeneral ? 'Make Restricted' : 'Make General',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: t.primary),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: t.textSecondary),
                onPressed: () => _openAddHolidayDialog(holiday),
                tooltip: 'Edit Holiday',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                onPressed: () => _deleteHoliday(holiday),
                tooltip: 'Delete Holiday',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ],
          );

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
                    child: actionButtons,
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
                  child: actionButtons,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyListState(AppThemeConfig t) {
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
            child: Icon(Icons.calendar_month_outlined, size: 48, color: t.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No Holiday List for $_selectedYear',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: t.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new Holiday List for $_selectedYear to add public holidays and restricted festival leaves.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: t.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createHolidayList,
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text('Create $_selectedYear Holiday List', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
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
            onPressed: _fetchHolidayList,
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
