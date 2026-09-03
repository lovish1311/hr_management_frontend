import 'package:flutter/material.dart';
import 'package:hr_management/core/theme/theme_manager.dart';
import 'package:hr_management/core/widgets/responsive_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final t = context.appTheme;
        final manager = ThemeManager.instance;

        return ResponsiveScaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Page Title ───────────────────────────────────────────────
                const Text('Appearance Settings',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Customize the look and feel of your enterprise portal.',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 32),

                // ── Color Theme Grid ─────────────────────────────────────────
                _card(
                  t: t,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(t, Icons.palette_rounded, 'Color Theme',
                          'Select your preferred color gradient and accent color.'),
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
                          final isActive = manager.currentTheme == type;
                          return _ThemeCard(
                            type: type,
                            config: cfg,
                            isActive: isActive,
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
                      _sectionHeader(t, Icons.text_format_rounded, 'Typography & Layout',
                          'Customize font sizes and data density.'),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _dropdownField(t, 'Font Family', manager.fontFamily,
                              ['Default', 'Inter', 'Roboto', 'Outfit', 'Poppins'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              (v) { if (v != null) manager.setFontFamily(v); })),
                          const SizedBox(width: 16),
                          Expanded(child: _dropdownField<double>(t, 'Font Size Scaling', manager.fontSizeMultiplier,
                              const [
                                DropdownMenuItem(value: 0.8, child: Text('Small (80%)')),
                                DropdownMenuItem(value: 1.0, child: Text('Default (100%)')),
                                DropdownMenuItem(value: 1.2, child: Text('Large (120%)')),
                              ],
                              (v) { if (v != null) manager.setFontSize(v); })),
                          const SizedBox(width: 16),
                          Expanded(child: _dropdownField(t, 'Density Mode', manager.densityMode,
                              ['Comfortable', 'Compact'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              (v) { if (v != null) manager.setDensityMode(v); })),
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
                      _sectionHeader(t, Icons.toggle_on_rounded, 'Preferences',
                          'Additional user interface preferences.'),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('Enable Animations', style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                        subtitle: Text('Toggle hover effects and micro-animations.', style: TextStyle(color: t.textSecondary)),
                        activeThumbColor: t.primary,
                        activeTrackColor: t.primary.withValues(alpha: 0.3),
                        value: manager.animationsEnabled,
                        onChanged: manager.setAnimationsEnabled,
                        contentPadding: EdgeInsets.zero,
                      ),
                      Divider(color: t.border),
                      SwitchListTile(
                        title: Text('Use 24-Hour Time', style: TextStyle(fontWeight: FontWeight.bold, color: t.text)),
                        subtitle: Text('Display times as 14:00 instead of 2:00 PM.', style: TextStyle(color: t.textSecondary)),
                        activeThumbColor: t.primary,
                        activeTrackColor: t.primary.withValues(alpha: 0.3),
                        value: manager.use24HourTime,
                        onChanged: manager.setUse24HourTime,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
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

  const _ThemeCard({required this.type, required this.config, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ThemeManager.instance.setTheme(type),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? config.primary : config.border.withValues(alpha: 0.5),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: config.glow, blurRadius: 12, spreadRadius: 2)]
              : [],
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
