import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hr_management/core/widgets/app_toast.dart';
import 'package:hr_management/features/banners/data/models/banner_model.dart';
import 'package:hr_management/features/banners/presentation/providers/banner_providers.dart';
import 'package:hr_management/features/employees/data/repositories/employee_repository_impl.dart';
import 'package:hr_management/features/employees/domain/entities/employee.dart';

/// Modal dialog for creating and editing promotional & celebration banners
class BannerManagementDialog extends ConsumerStatefulWidget {
  final BannerModel? initialBanner;

  const BannerManagementDialog({
    super.key,
    this.initialBanner,
  });

  static Future<void> show(BuildContext context, {BannerModel? initialBanner}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BannerManagementDialog(initialBanner: initialBanner),
    );
  }

  @override
  ConsumerState<BannerManagementDialog> createState() => _BannerManagementDialogState();
}

class _BannerManagementDialogState extends ConsumerState<BannerManagementDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _actionButtonTextController;
  late final TextEditingController _actionUrlController;
  String? _selectedDepartment;

  late BannerType _selectedType;
  CelebrationType _celebrationType = CelebrationType.birthday;
  BannerCategory _category = BannerCategory.announcement;

  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  int _displayOrder = 0;
  bool _isActive = true;

  // Image state
  Uint8List? _localImageBytes;
  String? _localImageFilename;
  String? _existingImageUrl;

  // Target Employee for Celebrations
  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _isLoadingEmployees = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final b = widget.initialBanner;
    _selectedType = b?.bannerType ?? BannerType.news;
    _celebrationType = b?.celebrationType ?? CelebrationType.birthday;
    _category = b?.category ?? BannerCategory.announcement;

    _titleController = TextEditingController(text: b?.title ?? '');
    _subtitleController = TextEditingController(text: b?.subtitle ?? '');
    _actionButtonTextController = TextEditingController(text: b?.actionButtonText ?? '');
    _actionUrlController = TextEditingController(text: b?.actionUrl ?? '');
    _selectedDepartment = (b?.targetDepartment != null && b!.targetDepartment!.isNotEmpty) ? b.targetDepartment : null;

    _existingImageUrl = b?.imageUrl;
    if (b != null) {
      _startDate = b.startDate;
      _expiryDate = b.expiryDate;
      _displayOrder = b.displayOrder;
      _isActive = b.isActive;
    }

    _loadEmployees();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _actionButtonTextController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final repo = EmployeeRepositoryImpl();
      final employees = await repo.getEmployees();
      if (!mounted) return;
      setState(() {
        _employees = employees;
        if (widget.initialBanner?.targetEmployeeId != null) {
          final targetIdStr = widget.initialBanner!.targetEmployeeId.toString();
          _selectedEmployee = employees.firstWhere(
            (e) => e.id == targetIdStr,
            orElse: () => employees.first,
          );
        }
        _isLoadingEmployees = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes == null) return;

      if (file.size > 5 * 1024 * 1024) {
        if (!mounted) return;
        AppToast.error(context, 'Image file exceeds maximum allowed limit of 5MB.');
        return;
      }

      setState(() {
        _localImageBytes = file.bytes;
        _localImageFilename = file.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate.isAfter(_expiryDate) || _startDate.isAtSameMomentAs(_expiryDate)) {
      AppToast.error(context, 'Start date must be strictly before expiration date.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? finalImageUrl = _existingImageUrl;

      // 1. Upload local image strictly upon submission if picked
      if (_localImageBytes != null && _localImageFilename != null) {
        final api = ref.read(bannerApiServiceProvider);
        finalImageUrl = await api.uploadImage(_localImageBytes!, _localImageFilename!);
      }

      // 2. Prepare payload
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        'bannerType': _selectedType.toServerString(),
        'category': _selectedType == BannerType.celebration
            ? (_celebrationType == CelebrationType.birthday ? 'BIRTHDAY' : 'CELEBRATION')
            : _category.toServerString(),
        'celebrationType': _selectedType == BannerType.celebration
            ? _celebrationType.toServerString()
            : null,
        'targetEmployeeId': _selectedType == BannerType.celebration
            ? _selectedEmployee?.id
            : null,
        'imageUrl': finalImageUrl,
        'actionUrl': _actionUrlController.text.trim().isEmpty ? null : _actionUrlController.text.trim(),
        'actionButtonText': _actionButtonTextController.text.trim().isEmpty ? null : _actionButtonTextController.text.trim(),
        'targetDepartment': (_selectedDepartment != null && _selectedDepartment!.trim().isNotEmpty) ? _selectedDepartment!.trim() : null,
        'startDate': _startDate.toIso8601String(),
        'expiryDate': _expiryDate.toIso8601String(),
        'displayOrder': _displayOrder,
        'isActive': _isActive,
      };

      if (widget.initialBanner != null) {
        payload['version'] = widget.initialBanner!.version;
        await ref.read(manageBannersProvider.notifier).updateBanner(widget.initialBanner!.id, payload);
        if (!mounted) return;
        AppToast.success(context, 'Banner updated successfully!');
      } else {
        await ref.read(manageBannersProvider.notifier).createBanner(payload);
        if (!mounted) return;
        AppToast.success(context, 'Banner published successfully!');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    // Watch active banners to compute live cap bar
    final activeBannersAsync = ref.watch(activeBannersProvider);
    final activeCount = activeBannersAsync.value?.length ?? 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: screenHeight * 0.90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.initialBanner != null ? Icons.edit_note_rounded : Icons.add_photo_alternate_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.initialBanner != null ? 'Edit Banner' : 'Create Banner & Post',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Live Concurrency Cap Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: (activeCount >= 15 ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (activeCount >= 15 ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              activeCount >= 15 ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                              size: 18,
                              color: activeCount >= 15 ? Colors.red : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Live Active Banners: $activeCount / 15 Max Capacity',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: activeCount >= 15 ? Colors.red : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 1. Primary Toggle: News vs Celebration (Select one only)
                      const Text(
                        'Select Banner Type',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _selectedType = BannerType.news;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedType == BannerType.news
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.newspaper_rounded,
                                        size: 18,
                                        color: _selectedType == BannerType.news ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'News',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _selectedType == BannerType.news ? Colors.white : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _selectedType = BannerType.celebration;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedType == BannerType.celebration
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cake_rounded,
                                        size: 18,
                                        color: _selectedType == BannerType.celebration ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Celebration',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _selectedType == BannerType.celebration ? Colors.white : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 2. Celebration Specific Fields
                      if (_selectedType == BannerType.celebration) ...[
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<CelebrationType>(
                                initialValue: _celebrationType,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Celebration Subtype',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: CelebrationType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type.displayName, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _celebrationType = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_isLoadingEmployees)
                          const LinearProgressIndicator()
                        else
                          DropdownButtonFormField<Employee>(
                            initialValue: _selectedEmployee,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Target Employee',
                              hintText: 'Select celebrating colleague',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _employees.map((emp) {
                              final name = '${emp.firstName} ${emp.lastName}'.trim();
                              return DropdownMenuItem(
                                value: emp,
                                child: Text(
                                  '$name (${emp.department.isNotEmpty ? emp.department : 'General'})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (emp) {
                              setState(() {
                                _selectedEmployee = emp;
                                if (emp != null && _titleController.text.isEmpty) {
                                  if (_celebrationType == CelebrationType.birthday) {
                                    _titleController.text = 'Happy Birthday, ${emp.firstName}!';
                                  } else {
                                    _titleController.text = 'Happy Work Anniversary, ${emp.firstName}!';
                                  }
                                }
                              });
                            },
                          ),
                        const SizedBox(height: 18),
                      ],

                      // 3. News Specific Category & Department Fields
                      if (_selectedType == BannerType.news) ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 400;
                            final categoryField = DropdownButtonFormField<BannerCategory>(
                              initialValue: _category,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                BannerCategory.announcement,
                                BannerCategory.festival,
                                BannerCategory.officeEvent,
                                BannerCategory.achievement,
                                BannerCategory.general,
                              ].map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.name.toUpperCase(), overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _category = val);
                              },
                            );

                            final deptAsync = ref.watch(bannerDepartmentsProvider);
                            final departments = deptAsync.value ?? [];
                            final List<DropdownMenuItem<String?>> deptItems = [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('🌐 All Departments', overflow: TextOverflow.ellipsis),
                              ),
                            ];
                            final allDepts = <String>{...departments};
                            if (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) {
                              allDepts.add(_selectedDepartment!);
                            }
                            for (final dept in allDepts) {
                              deptItems.add(DropdownMenuItem<String?>(
                                value: dept,
                                child: Text(dept, overflow: TextOverflow.ellipsis),
                              ));
                            }

                            final targetDeptField = DropdownButtonFormField<String?>(
                              initialValue: _selectedDepartment,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Target Department',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: deptAsync.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : null,
                              ),
                              items: deptItems,
                              onChanged: (val) {
                                setState(() {
                                  _selectedDepartment = val;
                                });
                              },
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  categoryField,
                                  const SizedBox(height: 12),
                                  targetDeptField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: categoryField),
                                const SizedBox(width: 12),
                                Expanded(child: targetDeptField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 4. Title & Subtitle
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Headline for banner',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _subtitleController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle / Description',
                          hintText: 'Supporting details',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5. Image Upload & Preview Card
                      const Text(
                        'Banner Cover Image (Max 5MB)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282C37) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_localImageBytes != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.memory(_localImageBytes!, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Local Preview: $_localImageFilename',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ] else if (_existingImageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Current Published Image', style: TextStyle(fontSize: 12)),
                            ],
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(_localImageBytes != null ? 'Change Local Image' : 'Pick Image File'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 6. Action Button & URL (for News)
                      if (_selectedType == BannerType.news) ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 400;
                            final actionBtnField = TextFormField(
                              controller: _actionButtonTextController,
                              decoration: const InputDecoration(
                                labelText: 'Action Button (Optional)',
                                hintText: 'e.g. RSVP Now',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            );
                            final actionUrlField = TextFormField(
                              controller: _actionUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Action URL (Optional)',
                                hintText: 'https://... or /engage',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  actionBtnField,
                                  const SizedBox(height: 12),
                                  actionUrlField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: actionBtnField),
                                const SizedBox(width: 12),
                                Expanded(child: actionUrlField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 7. Scheduling Dates
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 400;
                          final startBtn = OutlinedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) setState(() => _startDate = d);
                            },
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text('Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                          );

                          final expiryBtn = OutlinedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _expiryDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (d != null) setState(() => _expiryDate = d);
                            },
                            icon: const Icon(Icons.event_busy_rounded, size: 16),
                            label: Text('Expires: ${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}'),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                startBtn,
                                const SizedBox(height: 10),
                                expiryBtn,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: startBtn),
                              const SizedBox(width: 10),
                              Expanded(child: expiryBtn),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // 8. Active Toggle & Display Order
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Is Active', style: TextStyle(fontSize: 14)),
                              value: _isActive,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: _displayOrder.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Order',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                _displayOrder = int.tryParse(val) ?? 0;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.initialBanner != null ? 'Save Changes' : 'Publish Banner'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
