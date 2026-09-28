import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import '../../data/models/holiday_model.dart';
import '../../data/services/holiday_service.dart';

class AddHolidayDialog extends StatefulWidget {
  final int holidayListId;
  final int year;
  final HolidayModel? existingHoliday;

  const AddHolidayDialog({
    super.key,
    required this.holidayListId,
    required this.year,
    this.existingHoliday,
  });

  @override
  State<AddHolidayDialog> createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<AddHolidayDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedType;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final h = widget.existingHoliday;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descriptionController = TextEditingController(text: h?.description ?? '');
    _selectedDate = h?.date ?? DateTime(widget.year, 1, 1);
    _selectedType = h?.type ?? 'GENERAL';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final firstDate = DateTime(widget.year, 1, 1);
    final lastDate = DateTime(widget.year, 12, 31);
    final initialDate = _selectedDate.year == widget.year ? _selectedDate : firstDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final t = context.appTheme;
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: t.primary,
              onPrimary: Colors.white,
              surface: t.card,
              onSurface: t.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.existingHoliday != null) {
        await HolidayService.updateHoliday(
          id: widget.existingHoliday!.id!,
          name: _nameController.text.trim(),
          date: _selectedDate,
          type: _selectedType,
          description: _descriptionController.text.trim(),
        );
      } else {
        await HolidayService.addHoliday(
          holidayListId: widget.holidayListId,
          name: _nameController.text.trim(),
          date: _selectedDate,
          type: _selectedType,
          description: _descriptionController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final isEdit = widget.existingHoliday != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: t.card,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: t.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEdit ? Icons.edit_calendar_rounded : Icons.event_available_rounded,
                                color: t.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit ? 'Edit Holiday' : 'Add Holiday',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: t.text,
                                    ),
                                  ),
                                  Text(
                                    'Year ${widget.year} Holiday List',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: t.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: t.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Holiday Name
                  Text('Holiday Name / Occasion *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: t.text),
                    decoration: InputDecoration(
                      hintText: 'e.g. Independence Day, Diwali',
                      hintStyle: TextStyle(color: t.textSecondary.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: t.cardSoft,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.primary, width: 2)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a holiday name' : null,
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  Text('Date *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: t.cardSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, color: t.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "${_selectedDate.day.toString().padLeft(2, '0')} ${_monthName(_selectedDate.month)} ${_selectedDate.year}",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: t.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: t.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Change',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Holiday Type Selector
                  Text('Holiday Type *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeOption(
                          t: t,
                          type: 'GENERAL',
                          title: 'General Holiday',
                          subtitle: 'Automatic day off for all',
                          icon: Icons.celebration_rounded,
                          accentColor: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeOption(
                          t: t,
                          type: 'RESTRICTED',
                          title: 'Restricted Holiday',
                          subtitle: 'Optional, requires approval',
                          icon: Icons.event_note_rounded,
                          accentColor: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('Description / Notes (Optional)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: TextStyle(color: t.text),
                    decoration: InputDecoration(
                      hintText: 'Add brief context or notes...',
                      hintStyle: TextStyle(color: t.textSecondary.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: t.cardSoft,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: t.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(isEdit ? 'Save Changes' : 'Add Holiday', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required AppThemeConfig t,
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : t.cardSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : t.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isSelected ? accentColor : t.textSecondary),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 18, color: accentColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? accentColor : t.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: t.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
