import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import '../../data/models/query_ast.dart';
import '../../data/models/query_template.dart';
import '../../providers/query_builder_providers.dart';
import 'package:hr_management/core/widgets/app_toast.dart';

class TemplateManagementDialog extends ConsumerStatefulWidget {
  final QueryRequest currentRequest;
  final ValueChanged<QueryTemplate> onLoadTemplate;

  const TemplateManagementDialog({
    super.key,
    required this.currentRequest,
    required this.onLoadTemplate,
  });

  @override
  ConsumerState<TemplateManagementDialog> createState() => _TemplateManagementDialogState();
}

class _TemplateManagementDialogState extends ConsumerState<TemplateManagementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'EMPLOYEE';
  bool _isPublic = true;
  bool _isSaving = false;
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _category = widget.currentRequest.rootEntity;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final newTmpl = QueryTemplate(
        name: name,
        description: _descController.text.trim(),
        category: _category,
        isPublic: _isPublic,
        queryConfig: widget.currentRequest,
      );

      await ref.read(queryTemplatesProvider.notifier).saveTemplate(newTmpl);

      if (mounted) {
        AppToast.success(context, 'Template "$name" saved successfully.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to save template', rawError: e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDelete(int id, String name) async {
    setState(() => _deletingId = id);
    try {
      await ref.read(queryTemplatesProvider.notifier).removeTemplate(id);
      if (mounted) {
        AppToast.info(context, 'Template "$name" deleted.');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to delete template', rawError: e);
      }
    } finally {
      if (mounted) {
        setState(() => _deletingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final templatesAsync = ref.watch(queryTemplatesProvider);

    return Dialog(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: t.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_rounded, color: t.primary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Report Templates',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t.surfaceText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                indicatorColor: t.primary,
                labelColor: t.primary,
                unselectedLabelColor: t.textSecondary,
                tabs: const [
                  Tab(text: 'Save Current Query'),
                  Tab(text: 'Saved Templates'),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Save Template
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            style: TextStyle(color: t.surfaceText, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Template Name *',
                              hintText: 'e.g. Q4 Executive Salary Audit',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descController,
                            maxLines: 2,
                            style: TextStyle(color: t.surfaceText, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              hintText: 'Brief summary of audit criteria and purpose...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _category,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'EMPLOYEE', child: Text('Employee Profiles')),
                              DropdownMenuItem(value: 'ATTENDANCE', child: Text('Time & Attendance')),
                              DropdownMenuItem(value: 'LEAVES', child: Text('Leaves & Approvals')),
                              DropdownMenuItem(value: 'PAYROLL', child: Text('Payroll & Compensation')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _category = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Share with organization (Public)', style: TextStyle(fontSize: 13, color: t.surfaceText)),
                            value: _isPublic,
                            activeThumbColor: t.primary,
                            onChanged: (val) => setState(() => _isPublic = val),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_rounded, size: 16),
                              label: Text(_isSaving ? 'Saving Template...' : 'Save Template'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: t.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isSaving ? null : _handleSave,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Saved Templates List (with live Riverpod state)
                    templatesAsync.when(
                      loading: () => const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Loading templates...', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
                            const SizedBox(height: 8),
                            Text('Failed to load templates: $err', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () => ref.invalidate(queryTemplatesProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      data: (templates) {
                        if (templates.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bookmark_border_rounded, size: 36, color: t.textSecondary.withValues(alpha: 0.6)),
                                const SizedBox(height: 8),
                                Text(
                                  'No saved custom templates yet.',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.surfaceText),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Configure your query and save it from the first tab!',
                                  style: TextStyle(fontSize: 11, color: t.surfaceTextSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: templates.length,
                          separatorBuilder: (_, __) => Divider(color: t.border, height: 1),
                          itemBuilder: (context, index) {
                            final tmpl = templates[index];
                            final isDeleting = _deletingId == tmpl.id;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: t.primary.withValues(alpha: 0.15),
                                child: Icon(Icons.analytics_rounded, size: 16, color: t.primary),
                              ),
                              title: Text(
                                tmpl.name,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.surfaceText),
                              ),
                              subtitle: Text(
                                tmpl.description ?? tmpl.category ?? '',
                                style: TextStyle(fontSize: 11, color: t.surfaceTextSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.play_circle_fill_rounded, color: t.primary, size: 22),
                                    tooltip: 'Apply Template',
                                    onPressed: () {
                                      widget.onLoadTemplate(tmpl);
                                      Navigator.pop(context);
                                    },
                                  ),
                                  if (tmpl.id != null)
                                    isDeleting
                                        ? const Padding(
                                            padding: EdgeInsets.all(10),
                                            child: SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                            tooltip: 'Delete Template',
                                            onPressed: () => _handleDelete(tmpl.id!, tmpl.name),
                                          ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
