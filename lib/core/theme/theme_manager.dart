import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType {
  ocean,
  nebula,
  fire,
  arctic,
  midnight,
  forest,
  electric,
  royal,
  obsidian,
  sunset,
  aurora,
  cyberIce,
  solar,
}

/// Full semantic token set for one theme.
class AppThemeConfig {
  final String name;
  final String emoji;

  // ── Background ──────────────────────────────────────────────────────────────
  final List<Color> backgroundGradient; // 2-4 stops, used as the page backdrop
  final Color sidebar;

  // ── Brand ────────────────────────────────────────────────────────────────────
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accent;

  // ── Surfaces ─────────────────────────────────────────────────────────────────
  final Color card;      // e.g. dialog / card background
  final Color cardSoft;  // subtle tinted surface

  // ── Content ───────────────────────────────────────────────────────────────────
  final Color text;
  final Color textSecondary;
  final Color border;

  // ── Semantic ──────────────────────────────────────────────────────────────────
  final Color success;
  final Color warning;
  final Color danger;

  // ── Effects ───────────────────────────────────────────────────────────────────
  final Color glow;

  // ── MaterialApp ThemeMode ─────────────────────────────────────────────────────
  final ThemeMode themeMode;

  const AppThemeConfig({
    required this.name,
    required this.emoji,
    required this.backgroundGradient,
    required this.sidebar,
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.card,
    required this.cardSoft,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.glow,
    this.themeMode = ThemeMode.dark,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  SINGLETON MANAGER
// ─────────────────────────────────────────────────────────────────────────────

class ThemeManager extends ChangeNotifier {
  static final ThemeManager instance = ThemeManager._internal();
  ThemeManager._internal();

  AppThemeType _currentTheme = AppThemeType.ocean;
  double _fontSizeMultiplier = 1.0;
  String _fontFamily = 'Default';
  String _densityMode = 'Comfortable';
  bool _animationsEnabled = true;
  bool _use24HourTime = false;

  AppThemeType get currentTheme => _currentTheme;
  double get fontSizeMultiplier => _fontSizeMultiplier;
  String get fontFamily => _fontFamily;
  String get densityMode => _densityMode;
  bool get animationsEnabled => _animationsEnabled;
  bool get use24HourTime => _use24HourTime;

  AppThemeConfig get activeThemeConfig => themes[_currentTheme]!;

  // ─────────────────────────────────────────────────────────────────────────
  //  THEME DEFINITIONS  (source: colorsForApp.txt)
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<AppThemeType, AppThemeConfig> themes = {

    // 1 ── OCEAN ────────────────────────────────────────────────────────────
    AppThemeType.ocean: AppThemeConfig(
      name: 'Ocean', emoji: '🌊',
      backgroundGradient: [Color(0xFF071A2B), Color(0xFF064E5B), Color(0xFF0F766E)],
      sidebar:      Color(0xFFF8FAFC),
      primary:      Color(0xFF0EA5A4),
      primaryDark:  Color(0xFF0F766E),
      secondary:    Color(0xFF0284C7),
      accent:       Color(0xFF22D3EE),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFECFEFF),
      text:         Color(0xFF0F172A),
      textSecondary:Color(0xFF64748B),
      border:       Color(0xFFD7E7EA),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x4014B8A6),
      themeMode:    ThemeMode.light,
    ),

    // 2 ── NEBULA ───────────────────────────────────────────────────────────
    AppThemeType.nebula: AppThemeConfig(
      name: 'Nebula', emoji: '🌌',
      backgroundGradient: [Color(0xFF070B1F), Color(0xFF21104A), Color(0xFF701A75)],
      sidebar:      Color(0xFFF8FAFC),
      primary:      Color(0xFF8B5CF6),
      primaryDark:  Color(0xFF6D28D9),
      secondary:    Color(0xFFEC4899),
      accent:       Color(0xFFC084FC),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFF5F3FF),
      text:         Color(0xFF111827),
      textSecondary:Color(0xFF64748B),
      border:       Color(0xFFE9D5FF),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x408B5CF6),
      themeMode:    ThemeMode.light,
    ),

    // 3 ── FIRE ────────────────────────────────────────────────────────────
    AppThemeType.fire: AppThemeConfig(
      name: 'Fire', emoji: '🔥',
      backgroundGradient: [Color(0xFF170504), Color(0xFF571313), Color(0xFF9A3412)],
      sidebar:      Color(0xFFFFFBFA),
      primary:      Color(0xFFF97316),
      primaryDark:  Color(0xFFEA580C),
      secondary:    Color(0xFFEF4444),
      accent:       Color(0xFFFBBF24),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFFFF7ED),
      text:         Color(0xFF1C1917),
      textSecondary:Color(0xFF78716C),
      border:       Color(0xFFFED7AA),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFDC2626),
      glow:         Color(0x40F97316),
      themeMode:    ThemeMode.light,
    ),

    // 4 ── ARCTIC ──────────────────────────────────────────────────────────
    AppThemeType.arctic: AppThemeConfig(
      name: 'Arctic', emoji: '❄️',
      backgroundGradient: [Color(0xFF031525), Color(0xFF075985), Color(0xFF0E7490)],
      sidebar:      Color(0xFFF8FAFC),
      primary:      Color(0xFF06B6D4),
      primaryDark:  Color(0xFF0891B2),
      secondary:    Color(0xFF3B82F6),
      accent:       Color(0xFF67E8F9),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFECFEFF),
      text:         Color(0xFF0F172A),
      textSecondary:Color(0xFF64748B),
      border:       Color(0xFFBAE6FD),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x4022D3EE),
      themeMode:    ThemeMode.light,
    ),

    // 5 ── MIDNIGHT ────────────────────────────────────────────────────────
    AppThemeType.midnight: AppThemeConfig(
      name: 'Midnight', emoji: '🌑',
      backgroundGradient: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF172554)],
      sidebar:      Color(0xFF0B1120),
      primary:      Color(0xFF3B82F6),
      primaryDark:  Color(0xFF2563EB),
      secondary:    Color(0xFF6366F1),
      accent:       Color(0xFF60A5FA),
      card:         Color(0xFF111827),
      cardSoft:     Color(0xFF172033),
      text:         Color(0xFFF8FAFC),
      textSecondary:Color(0xFF94A3B8),
      border:       Color(0xFF263449),
      success:      Color(0xFF22C55E),
      warning:      Color(0xFFFBBF24),
      danger:       Color(0xFFF87171),
      glow:         Color(0x403B82F6),
      themeMode:    ThemeMode.dark,
    ),

    // 6 ── FOREST ──────────────────────────────────────────────────────────
    AppThemeType.forest: AppThemeConfig(
      name: 'Forest', emoji: '🌲',
      backgroundGradient: [Color(0xFF03140D), Color(0xFF064E3B), Color(0xFF047857)],
      sidebar:      Color(0xFFF7FCF9),
      primary:      Color(0xFF10B981),
      primaryDark:  Color(0xFF059669),
      secondary:    Color(0xFF16A34A),
      accent:       Color(0xFF34D399),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFECFDF5),
      text:         Color(0xFF0F172A),
      textSecondary:Color(0xFF64748B),
      border:       Color(0xFFBBF7D0),
      success:      Color(0xFF16A34A),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x4010B981),
      themeMode:    ThemeMode.light,
    ),

    // 7 ── ELECTRIC ────────────────────────────────────────────────────────
    AppThemeType.electric: AppThemeConfig(
      name: 'Electric', emoji: '⚡',
      backgroundGradient: [Color(0xFF050817), Color(0xFF172554), Color(0xFF1D4ED8)],
      sidebar:      Color(0xFFF8FAFC),
      primary:      Color(0xFF2563EB),
      primaryDark:  Color(0xFF1D4ED8),
      secondary:    Color(0xFF06B6D4),
      accent:       Color(0xFF38BDF8),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFEFF6FF),
      text:         Color(0xFF0F172A),
      textSecondary:Color(0xFF64748B),
      border:       Color(0xFFBFDBFE),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x403B82F6),
      themeMode:    ThemeMode.light,
    ),

    // 8 ── ROYAL ───────────────────────────────────────────────────────────
    AppThemeType.royal: AppThemeConfig(
      name: 'Royal', emoji: '👑',
      backgroundGradient: [Color(0xFF0D0618), Color(0xFF3B0764), Color(0xFF701A75)],
      sidebar:      Color(0xFFFCFAFF),
      primary:      Color(0xFF9333EA),
      primaryDark:  Color(0xFF7E22CE),
      secondary:    Color(0xFFC026D3),
      accent:       Color(0xFFF59E0B),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFFAF5FF),
      text:         Color(0xFF18181B),
      textSecondary:Color(0xFF71717A),
      border:       Color(0xFFE9D5FF),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x40A855F7),
      themeMode:    ThemeMode.light,
    ),

    // 9 ── OBSIDIAN ────────────────────────────────────────────────────────
    AppThemeType.obsidian: AppThemeConfig(
      name: 'Obsidian', emoji: '🖤',
      backgroundGradient: [Color(0xFF000000), Color(0xFF111111), Color(0xFF262626)],
      sidebar:      Color(0xFF0A0A0A),
      primary:      Color(0xFFE5E5E5),
      primaryDark:  Color(0xFFA3A3A3),
      secondary:    Color(0xFF737373),
      accent:       Color(0xFFFFFFFF),
      card:         Color(0xFF171717),
      cardSoft:     Color(0xFF1F1F1F),
      text:         Color(0xFFFAFAFA),
      textSecondary:Color(0xFFA3A3A3),
      border:       Color(0xFF303030),
      success:      Color(0xFF22C55E),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x20FFFFFF),
      themeMode:    ThemeMode.dark,
    ),

    // 10 ── SUNSET ─────────────────────────────────────────────────────────
    AppThemeType.sunset: AppThemeConfig(
      name: 'Sunset', emoji: '🌅',
      backgroundGradient: [Color(0xFF180B2B), Color(0xFF831843), Color(0xFFC2410C)],
      sidebar:      Color(0xFFFFFBFA),
      primary:      Color(0xFFF43F5E),
      primaryDark:  Color(0xFFE11D48),
      secondary:    Color(0xFFF97316),
      accent:       Color(0xFFFBBF24),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFFFF1F2),
      text:         Color(0xFF1C1917),
      textSecondary:Color(0xFF78716C),
      border:       Color(0xFFFED7AA),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFE11D48),
      glow:         Color(0x40F43F5E),
      themeMode:    ThemeMode.light,
    ),

    // 11 ── AURORA ─────────────────────────────────────────────────────────
    AppThemeType.aurora: AppThemeConfig(
      name: 'Aurora', emoji: '🌌',
      backgroundGradient: [Color(0xFF04121A), Color(0xFF064E5B), Color(0xFF312E81), Color(0xFF701A75)],
      sidebar:      Color(0xFFF8FAFC),
      primary:      Color(0xFF14B8A6),
      primaryDark:  Color(0xFF0F766E),
      secondary:    Color(0xFF8B5CF6),
      accent:       Color(0xFF2DD4BF),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFF0FDFA),
      text:         Color(0xFF111827),
      textSecondary:Color(0xFF64748B),
      border:       Color(0xFFCCFBF1),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x402DD4BF),
      themeMode:    ThemeMode.light,
    ),

    // 12 ── CYBER ICE ──────────────────────────────────────────────────────
    AppThemeType.cyberIce: AppThemeConfig(
      name: 'Cyber Ice', emoji: '🧊',
      backgroundGradient: [Color(0xFF020617), Color(0xFF0C4A6E), Color(0xFF155E75)],
      sidebar:      Color(0xFFF8FAFC),
      primary:      Color(0xFF22D3EE),
      primaryDark:  Color(0xFF0891B2),
      secondary:    Color(0xFF6366F1),
      accent:       Color(0xFFA5F3FC),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFECFEFF),
      text:         Color(0xFF0F172A),
      textSecondary:Color(0xFF64748B),
      border:       Color(0xFFA5F3FC),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x5022D3EE),
      themeMode:    ThemeMode.light,
    ),

    // 13 ── SOLAR ──────────────────────────────────────────────────────────
    AppThemeType.solar: AppThemeConfig(
      name: 'Solar', emoji: '☀️',
      backgroundGradient: [Color(0xFF160B02), Color(0xFF78350F), Color(0xFFB45309)],
      sidebar:      Color(0xFFFFFCF5),
      primary:      Color(0xFFF59E0B),
      primaryDark:  Color(0xFFD97706),
      secondary:    Color(0xFFEA580C),
      accent:       Color(0xFFFDE68A),
      card:         Color(0xFFFFFFFF),
      cardSoft:     Color(0xFFFFFBEB),
      text:         Color(0xFF1C1917),
      textSecondary:Color(0xFF78716C),
      border:       Color(0xFFFDE68A),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFD97706),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x40F59E0B),
      themeMode:    ThemeMode.light,
    ),
  };

  // ─────────────────────────────────────────────────────────────────────────
  //  PERSISTENCE
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('selected_theme');
    if (themeStr != null) {
      _currentTheme = AppThemeType.values.firstWhere(
        (e) => e.toString().split('.').last == themeStr,
        orElse: () => AppThemeType.ocean,
      );
    }
    _fontSizeMultiplier = prefs.getDouble('font_size') ?? 1.0;
    _fontFamily = prefs.getString('font_family') ?? 'Default';
    _densityMode = prefs.getString('density_mode') ?? 'Comfortable';
    _animationsEnabled = prefs.getBool('animations_enabled') ?? true;
    _use24HourTime = prefs.getBool('use_24h_time') ?? false;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType type) async {
    _currentTheme = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', type.toString().split('.').last);
  }

  Future<void> setFontSize(double size) async {
    _fontSizeMultiplier = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size', size);
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_family', family);
  }

  Future<void> setDensityMode(String mode) async {
    _densityMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('density_mode', mode);
  }

  Future<void> setAnimationsEnabled(bool enabled) async {
    _animationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animations_enabled', enabled);
  }

  Future<void> setUse24HourTime(bool use24h) async {
    _use24HourTime = use24h;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_24h_time', use24h);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BuildContext EXTENSION  ─  usage: context.appTheme.primary
// ─────────────────────────────────────────────────────────────────────────────
extension AppThemeContext on BuildContext {
  AppThemeConfig get appTheme => ThemeManager.instance.activeThemeConfig;
}
