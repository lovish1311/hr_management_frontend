import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hr_management/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:hr_management/features/attendance/domain/repositories/attendance_repository.dart';

class BiometricImportDialog extends StatefulWidget {
  final VoidCallback onImportSuccess;

  const BiometricImportDialog({super.key, required this.onImportSuccess});

  @override
  State<BiometricImportDialog> createState() => _BiometricImportDialogState();
}

class _BiometricImportDialogState extends State<BiometricImportDialog> {
  final AttendanceRepository _repository = AttendanceRepositoryImpl();
  DateTime _selectedDate = DateTime.now();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _errorMessage;
  Map<String, dynamic>? _importSummary;

  Future<void> _pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _errorMessage = null;
          _importSummary = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _uploadAndProcess() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      setState(() {
        _errorMessage = 'Please select a valid Excel (.xlsx) file first.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _repository.importBiometricExcel(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        targetDate: _selectedDate,
      );

      if (summary != null) {
        setState(() {
          _importSummary = summary;
          _isUploading = false;
        });

        widget.onImportSuccess();
      } else {
        setState(() {
          _errorMessage = 'Server error processing biometric file.';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process biometric file: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.upload_file_rounded, color: Color(0xFF6366F1), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Biometric Punch Log',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Parse punch machine Excel report & sync attendance',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Date Picker Field
              Text(
                'Select Punch Log Date',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF6366F1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // File Selection Box
              Text(
                'Upload Punch Machine Excel (.xlsx)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickExcelFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.note_add_rounded, size: 36, color: Color(0xFF6366F1)),
                      const SizedBox(height: 10),
                      Text(
                        _selectedFile != null ? _selectedFile!.name : 'Click to Browse & Select Punch Log Excel File',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedFile != null ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Size: ${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 20),

              // Import Results Preview Summary Card
              if (_importSummary != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 8),
                          Text('Biometric Excel Import Completed!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryBadge('Processed', '${_importSummary!['totalProcessed']}', Colors.blue),
                          _buildSummaryBadge('Present', '${_importSummary!['presentCount']}', const Color(0xFF10B981)),
                          _buildSummaryBadge('Late', '${_importSummary!['lateCount']}', const Color(0xFFF59E0B)),
                          _buildSummaryBadge('Absent', '${_importSummary!['absentCount']}', const Color(0xFFEF4444)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_importSummary!['rows'] != null) ...[
                        _buildDetailedList(
                          (_importSummary!['rows'] as List).cast<Map<String, dynamic>>(),
                          'LATE',
                          'Late Arrivals',
                          const Color(0xFFF59E0B),
                          isDark,
                        ),
                        _buildDetailedList(
                          (_importSummary!['rows'] as List).cast<Map<String, dynamic>>(),
                          'ABSENT',
                          'Absent Employees',
                          const Color(0xFFEF4444),
                          isDark,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_importSummary != null) ...[
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('OK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isUploading || _selectedFile == null ? null : _uploadAndProcess,
                      icon: _isUploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.flash_on_rounded, size: 18),
                      label: Text(_isUploading ? 'Processing...' : 'Process & Sync Batch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetailedList(List<Map<String, dynamic>> rows, String status, String title, Color color, bool isDark) {
    final filtered = rows.where((r) => r['status'] == status).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status == 'LATE' ? Icons.access_time_rounded : Icons.person_off_rounded, color: color, size: 16),
              const SizedBox(width: 6),
              Text('$title (${filtered.length})', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              itemBuilder: (context, index) {
                final row = filtered[index];
                final name = row['employeeName'] ?? 'Unknown Employee';
                final time = status == 'LATE' ? (row['checkInTime'] ?? 'No punch') : 'No punch';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                      if (status == 'LATE')
                        Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
