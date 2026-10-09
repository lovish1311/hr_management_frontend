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

  bool _isApplying = false;

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
    if (_isApplying) return;
    setState(() => _isApplying = true);

    try {
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
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final t = context.appTheme;
        final hasChanges = _hasChanges;

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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final cols = constraints.maxWidth > 700 ? 4 : (constraints.maxWidth > 420 ? 3 : 2);
                                final ratio = constraints.maxWidth > 700 ? 1.05 : 1.0;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: ratio,
                                  ),
                                  itemCount: ThemeManager.themes.length,
                                  itemBuilder: (context, index) {
                                    final type = ThemeManager.themes.keys.elementAt(index);
                                    final cfg = ThemeManager.themes[type]!;
                                    final isDraftActive = _draftTheme == type;
                                    return RepaintBoundary(
                                      child: _ThemeCard(
                                        type: type,
                                        config: cfg,
                                        isActive: isDraftActive,
                                        onSelect: () {
                                          setState(() {
                                            _draftTheme = type;
                                          });
                                        },
                                      ),
                                    );
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 620;

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _dropdownField(
                                        t,
                                        'Font Family',
                                        _draftFontFamily,
                                        ['Default', 'Inter', 'Roboto', 'Outfit', 'Poppins', 'Lato', 'Chilanka (Chillar)']
                                            .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                                            .toList(),
                                        (v) {
                                          if (v != null) {
                                            setState(() {
                                              _draftFontFamily = v;
                                            });
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _dropdownField<double>(
                                              t,
                                              'Font Size Scaling',
                                              _draftFontSize,
                                              const [
                                                DropdownMenuItem(value: 0.8, child: Text('80% (Small)', overflow: TextOverflow.ellipsis)),
                                                DropdownMenuItem(value: 1.0, child: Text('100% (Default)', overflow: TextOverflow.ellipsis)),
                                                DropdownMenuItem(value: 1.2, child: Text('120% (Large)', overflow: TextOverflow.ellipsis)),
                                                DropdownMenuItem(value: 1.4, child: Text('140% (Extra Large)', overflow: TextOverflow.ellipsis)),
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
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: _dropdownField(
                                              t,
                                              'Density Mode',
                                              _draftDensityMode,
                                              ['Comfortable', 'Compact']
                                                  .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
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
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: _dropdownField(
                                        t,
                                        'Font Family',
                                        _draftFontFamily,
                                        ['Default', 'Inter', 'Roboto', 'Outfit', 'Poppins', 'Lato', 'Chilanka (Chillar)']
                                            .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
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
                                          DropdownMenuItem(value: 0.8, child: Text('80% (Small)', overflow: TextOverflow.ellipsis)),
                                          DropdownMenuItem(value: 1.0, child: Text('100% (Default)', overflow: TextOverflow.ellipsis)),
                                          DropdownMenuItem(value: 1.2, child: Text('120% (Large)', overflow: TextOverflow.ellipsis)),
                                          DropdownMenuItem(value: 1.4, child: Text('140% (Extra Large)', overflow: TextOverflow.ellipsis)),
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
                                            .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
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
                                );
                              },
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
                            Material(
                              color: Colors.transparent,
                              child: SwitchListTile(
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: t.card,
                  border: Border(top: BorderSide(color: t.border, width: 1.2)),
                  boxShadow: [
                    BoxShadow(color: t.glow, blurRadius: 16, offset: const Offset(0, -4)),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                    final isCompact = constraints.maxWidth < (textScale > 1.2 ? 780 : 560);

                    if (isCompact) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: t.text,
                              side: BorderSide(color: t.border),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _resetToDefaults,
                            icon: const Icon(Icons.restart_alt_rounded, size: 16),
                            label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (hasChanges)
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: t.textSecondary,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  onPressed: _isApplying ? null : _cancelDraft,
                                  child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Cancel', style: TextStyle(fontSize: 12))),
                                ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: t.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  elevation: hasChanges ? 4 : 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: (hasChanges && !_isApplying) ? _applyChanges : null,
                                icon: _isApplying
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_rounded, size: 16),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _isApplying ? 'Applying...' : (hasChanges ? 'Apply' : 'Applied'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: t.text,
                            side: BorderSide(color: t.border),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isApplying ? null : _resetToDefaults,
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Reset to Default', style: TextStyle(fontWeight: FontWeight.bold))),
                        ),
                        const Spacer(),

                        if (hasChanges) ...[
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: t.textSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                            onPressed: _isApplying ? null : _cancelDraft,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Cancel / Revert'),
                          ),
                          const SizedBox(width: 12),
                        ],

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            elevation: hasChanges ? 4 : 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: (hasChanges && !_isApplying) ? _applyChanges : null,
                          icon: _isApplying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            _isApplying ? 'Applying...' : (hasChanges ? 'Apply Changes' : 'Applied'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
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
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text)),
            ),
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
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: t.text)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: t.card,
          style: TextStyle(color: t.text, fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: t.cardSoft,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.primary, width: 1.5)),
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
            color: isActive ? config.primary : config.border.withValues(alpha: 0.6),
            width: isActive ? 2.5 : 1.2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: config.glow.withValues(alpha: 0.5),
                    blurRadius: 14,
                    spreadRadius: 1.5,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              // Gradient preview with centered emoji & top-right check badge
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
                    // Centered Theme Emoji
                    Center(
                      child: Text(
                        config.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    // Perfectly aligned selection checkbox / badge at top-right
                    Positioned(
                      top: 7,
                      right: 7,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? config.primary : Colors.black.withValues(alpha: 0.28),
                          border: Border.all(
                            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: config.primary.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: isActive
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              // Theme Name Footer with contrast-safe text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                color: config.card,
                child: Text(
                  config.name,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? config.primary : config.surfaceText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
