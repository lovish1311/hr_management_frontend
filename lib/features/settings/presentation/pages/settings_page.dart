import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppThemeType _draftTheme;
  late double _draftFontSize;
  late String _draftFontFamily;
  late String _draftDensityMode;
  late bool _draftUse24HourTime;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final manager = ThemeManager.instance;
    _draftTheme = manager.currentTheme;
    _draftFontSize = manager.fontSizeMultiplier;
    _draftFontFamily = manager.fontFamily;
    _draftDensityMode = manager.densityMode;
    _draftUse24HourTime = manager.use24HourTime;
  }

  bool get _hasChanges {
    final manager = ThemeManager.instance;
    return _draftTheme != manager.currentTheme ||
        _draftFontSize != manager.fontSizeMultiplier ||
        _draftFontFamily != manager.fontFamily ||
        _draftDensityMode != manager.densityMode ||
        _draftUse24HourTime != manager.use24HourTime;
  }

  void _resetToDefaults() {
    setState(() {
      _draftTheme = AppThemeType.ocean;
      _draftFontSize = 1.0;
      _draftFontFamily = 'Default';
      _draftDensityMode = 'Comfortable';
      _draftUse24HourTime = false;
    });
  }

  void _cancelDraft() {
    setState(() {
      _loadCurrentSettings();
    });
  }

  Future<void> _applyChanges() async {
    await ThemeManager.instance.applySettingsBatch(
      theme: _draftTheme,
      fontSizeMultiplier: _draftFontSize,
      fontFamily: _draftFontFamily,
      densityMode: _draftDensityMode,
      use24HourTime: _draftUse24HourTime,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings applied successfully!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final t = context.appTheme;

        return ResponsiveScaffold(
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Page Title ───────────────────────────────────────────────
                      Text(
                        'Appearance Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: t.onBackgroundText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Customize the look and feel of your enterprise portal.',
                        style: TextStyle(
                          fontSize: 14,
                          color: t.onBackgroundTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Color Theme Grid ─────────────────────────────────────────
                      _card(
                        t: t,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              t,
                              Icons.palette_rounded,
                              'Color Theme',
                              'Select your preferred color gradient and accent color.',
                            ),
                            const SizedBox(height: 24),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 1.15,
                              ),
                              itemCount: ThemeManager.themes.length,
                              itemBuilder: (context, index) {
                                final type = ThemeManager.themes.keys.elementAt(index);
                                final cfg = ThemeManager.themes[type]!;
                                final isDraftActive = _draftTheme == type;
                                return _ThemeCard(
                                  type: type,
                                  config: cfg,
                                  isActive: isDraftActive,
                                  onSelect: () {
                                    setState(() {
                                      _draftTheme = type;
                                    });
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Typography & Layout ──────────────────────────────────────
                      _card(
                        t: t,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              t,
                              Icons.text_format_rounded,
                              'Typography & Layout',
                              'Customize font styles, font scaling, and layout density.',
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _dropdownField(
                                    t,
                                    'Font Family',
                                    _draftFontFamily,
                                    ['Default', 'Inter', 'Roboto', 'Outfit', 'Poppins', 'Lato', 'Chilanka (Chillar)']
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList(),
                                    (v) {
                                      if (v != null) {
                                        setState(() {
                                          _draftFontFamily = v;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _dropdownField<double>(
                                    t,
                                    'Font Size Scaling',
                                    _draftFontSize,
                                    const [
                                      DropdownMenuItem(value: 0.8, child: Text('Small (80%)')),
                                      DropdownMenuItem(value: 1.0, child: Text('Default (100%)')),
                                      DropdownMenuItem(value: 1.2, child: Text('Large (120%)')),
                                      DropdownMenuItem(value: 1.4, child: Text('Extra Large (140%)')),
                                    ],
                                    (v) {
                                      if (v != null) {
                                        setState(() {
                                          _draftFontSize = v;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _dropdownField(
                                    t,
                                    'Density Mode',
                                    _draftDensityMode,
                                    ['Comfortable', 'Compact']
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList(),
                                    (v) {
                                      if (v != null) {
                                        setState(() {
                                          _draftDensityMode = v;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Preferences ──────────────────────────────────────────────
                      _card(
                        t: t,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                              t,
                              Icons.toggle_on_rounded,
                              'Preferences',
                              'Additional user interface preferences.',
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: Text('Use 24-Hour Time', style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                              subtitle: Text('Display times as 14:00 instead of 2:00 PM.', style: TextStyle(color: t.textSecondary)),
                              activeThumbColor: t.primary,
                              activeTrackColor: t.primary.withValues(alpha: 0.3),
                              value: _draftUse24HourTime,
                              onChanged: (v) {
                                setState(() {
                                  _draftUse24HourTime = v;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ── Floating Action Bar (Reset, Cancel, Apply Changes) ───────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: t.card,
                  border: Border(top: BorderSide(color: t.border, width: 1.2)),
                  boxShadow: [
                    BoxShadow(color: t.glow, blurRadius: 16, offset: const Offset(0, -4)),
                  ],
                ),
                child: Row(
                  children: [
                    // Reset to Default Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.text,
                        side: BorderSide(color: t.border),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reset to Default', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),

                    // Cancel / Revert Button
                    if (_hasChanges) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: t.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                        onPressed: _cancelDraft,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Cancel / Revert'),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Apply Changes Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        elevation: _hasChanges ? 4 : 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _hasChanges ? _applyChanges : null,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        _hasChanges ? 'Apply Changes' : 'Applied',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _card({required AppThemeConfig t, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
        boxShadow: [BoxShadow(color: t.glow, blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(AppThemeConfig t, IconData icon, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: t.primary, size: 22),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 13, color: t.textSecondary)),
      ],
    );
  }

  Widget _dropdownField<T>(
    AppThemeConfig t,
    String label,
    T value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: t.text)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          dropdownColor: t.card,
          style: TextStyle(color: t.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: t.cardSoft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Theme Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  final AppThemeType type;
  final AppThemeConfig config;
  final bool isActive;
  final VoidCallback onSelect;

  const _ThemeCard({
    required this.type,
    required this.config,
    required this.isActive,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? config.primary : config.border.withValues(alpha: 0.5),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive ? [BoxShadow(color: config.glow, blurRadius: 12, spreadRadius: 2)] : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              // Gradient preview
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: config.backgroundGradient,
                        ),
                      ),
                    ),
                    if (isActive)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    // Accent dot indicator
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: config.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Label
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: config.card,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(config.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      config.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? config.primary : config.text,
                      ),
                      textAlign: TextAlign.center,
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

