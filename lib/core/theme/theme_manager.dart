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
  // Light Themes (from Ripple ThemeConfig)
  lavenderMist,
  nordicFrost,
  mintBreeze,
  solarAmber,
  roseSunset,
  light,
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

  // ── Surfaces (Complementing secondary color, never boring pure white) ────────
  final Color card;      // Card and container surface complementing background
  final Color cardSoft;  // Inset surface for text fields, chips, and nested tiles

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

  /// True if this theme behaves as a dark theme (dark surfaces, light text).
  /// In dark themes text is mostly white and in light themes text is mostly dark (matching Ripple ThemeConfig classification).
  bool get isDarkTheme => themeMode == ThemeMode.dark || isCardDark;

  /// True if the top/primary color of the background gradient is dark
  bool get isBackgroundDark => backgroundGradient.first.computeLuminance() < 0.45;

  /// True if the card surface color is dark
  bool get isCardDark => card.computeLuminance() < 0.45;

  /// Color for text sitting directly over the page background gradient (e.g. headers, section titles)
  Color get onBackgroundText => isDarkTheme ? Colors.white : (text.computeLuminance() < 0.45 ? text : const Color(0xFF0F172A));

  /// Color for secondary text sitting directly over the page background gradient
  Color get onBackgroundTextSecondary => isDarkTheme ? Colors.white.withValues(alpha: 0.75) : (textSecondary.computeLuminance() < 0.55 ? textSecondary : const Color(0xFF475569));

  /// Convenient aliases for section headers on background
  Color get headerText => onBackgroundText;
  Color get headerTextSecondary => onBackgroundTextSecondary;

  /// Contrast-safe primary text color on card surfaces (white in dark themes, dark slate in light themes).
  Color get surfaceText => isDarkTheme
      ? (text.computeLuminance() > 0.5 ? text : const Color(0xFFF8FAFC))
      : (text.computeLuminance() < 0.5 ? text : const Color(0xFF0F172A));

  /// Contrast-safe secondary text color on card surfaces.
  Color get surfaceTextSecondary => isDarkTheme
      ? (textSecondary.computeLuminance() > 0.4 ? textSecondary : const Color(0xFF94A3B8))
      : (textSecondary.computeLuminance() < 0.6 ? textSecondary : const Color(0xFF64748B));
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
  //  THEME DEFINITIONS
  //  Every dark theme uses rich, tinted secondary card colors complementing
  //  the background (no boring stark white cards all over).
  // ─────────────────────────────────────────────────────────────────────────

  static const Map<AppThemeType, AppThemeConfig> themes = {

    // 1 ── OCEAN (Deep Oceanic Teal & Cyan Tinted Surfaces) ───────────────────
    AppThemeType.ocean: AppThemeConfig(
      name: 'Ocean', emoji: '🌊',
      backgroundGradient: [Color(0xFF04131D), Color(0xFF072B3B), Color(0xFF0A444E)],
      sidebar:      Color(0xFF030E17),
      primary:      Color(0xFF0EA5A4),
      primaryDark:  Color(0xFF0F766E),
      secondary:    Color(0xFF0284C7),
      accent:       Color(0xFF22D3EE),
      card:         Color(0xFF0C2433), // Deep oceanic slate, complementing background
      cardSoft:     Color(0xFF071924), // Subtle darker inset for inputs/chips
      text:         Color(0xFFF0FDFA), // Crisp white with soft mint tint
      textSecondary:Color(0xFF80DEEA), // Soft cyan muted secondary
      border:       Color(0xFF14455C), // Complementing ocean border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x350EA5A4),
      themeMode:    ThemeMode.dark,
    ),

    // 2 ── NEBULA (Deep Cosmic Violet & Purple Tinted Surfaces) ──────────────
    AppThemeType.nebula: AppThemeConfig(
      name: 'Nebula', emoji: '🌌',
      backgroundGradient: [Color(0xFF070414), Color(0xFF1B0C3B), Color(0xFF581363)],
      sidebar:      Color(0xFF080314),
      primary:      Color(0xFFC084FC),
      primaryDark:  Color(0xFF9333EA),
      secondary:    Color(0xFFF472B6),
      accent:       Color(0xFFE879F9),
      card:         Color(0xFF22113A), // Deep cosmic purple card surface
      cardSoft:     Color(0xFF160A27), // Soft purple inset
      text:         Color(0xFFF8FAFC), // Pure crisp white
      textSecondary:Color(0xFFD8B4FE), // Lavender secondary text
      border:       Color(0xFF451E75), // Cosmic purple border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x358B5CF6),
      themeMode:    ThemeMode.dark,
    ),

    // 3 ── FIRE (Deep Charred Ember & Warm Amber Tinted Surfaces) ────────────
    AppThemeType.fire: AppThemeConfig(
      name: 'Fire', emoji: '🔥',
      backgroundGradient: [Color(0xFF140403), Color(0xFF420D0D), Color(0xFF78250C)],
      sidebar:      Color(0xFF110302),
      primary:      Color(0xFFF97316),
      primaryDark:  Color(0xFFEA580C),
      secondary:    Color(0xFFEF4444),
      accent:       Color(0xFFFBBF24),
      card:         Color(0xFF301007), // Deep ember espresso card
      cardSoft:     Color(0xFF1F0A04), // Dark inset
      text:         Color(0xFFFFF7ED), // Warm ivory white
      textSecondary:Color(0xFFFED7AA), // Peach muted secondary
      border:       Color(0xFF5C200E), // Warm flame border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFDC2626),
      glow:         Color(0x35F97316),
      themeMode:    ThemeMode.dark,
    ),

    // 4 ── ARCTIC (Deep Glacial Blue & Indigo Tinted Surfaces) ───────────────
    AppThemeType.arctic: AppThemeConfig(
      name: 'Arctic', emoji: '❄️',
      backgroundGradient: [Color(0xFF03101C), Color(0xFF063B57), Color(0xFF085B73)],
      sidebar:      Color(0xFF020B13),
      primary:      Color(0xFF06B6D4),
      primaryDark:  Color(0xFF0891B2),
      secondary:    Color(0xFF3B82F6),
      accent:       Color(0xFF67E8F9),
      card:         Color(0xFF0B253B), // Deep glacial navy card
      cardSoft:     Color(0xFF061828), // Inset
      text:         Color(0xFFF0FDF4), // Glacial white
      textSecondary:Color(0xFF7DD3FC), // Sky blue secondary
      border:       Color(0xFF124368), // Icy border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x3522D3EE),
      themeMode:    ThemeMode.dark,
    ),

    // 5 ── MIDNIGHT (Executive Dark Slate & Navy Tinted Surfaces) ─────────────
    AppThemeType.midnight: AppThemeConfig(
      name: 'Midnight', emoji: '🌑',
      backgroundGradient: [Color(0xFF020617), Color(0xFF0B132B), Color(0xFF101F3D)],
      sidebar:      Color(0xFF060D18),
      primary:      Color(0xFF3B82F6),
      primaryDark:  Color(0xFF2563EB),
      secondary:    Color(0xFF6366F1),
      accent:       Color(0xFF60A5FA),
      card:         Color(0xFF0D1B2D), // Exactly like screenshot 2
      cardSoft:     Color(0xFF081220), // Inset slate navy
      text:         Color(0xFFF8FAFC), // Pure bright white
      textSecondary:Color(0xFF94A3B8), // Soft slate gray
      border:       Color(0xFF1E324F), // Slate border
      success:      Color(0xFF22C55E),
      warning:      Color(0xFFFBBF24),
      danger:       Color(0xFFF87171),
      glow:         Color(0x353B82F6),
      themeMode:    ThemeMode.dark,
    ),

    // 6 ── FOREST (Deep Pine Emerald & Spruce Tinted Surfaces) ───────────────
    AppThemeType.forest: AppThemeConfig(
      name: 'Forest', emoji: '🌲',
      backgroundGradient: [Color(0xFF02120C), Color(0xFF04382A), Color(0xFF03543D)],
      sidebar:      Color(0xFF020E09),
      primary:      Color(0xFF10B981),
      primaryDark:  Color(0xFF059669),
      secondary:    Color(0xFF16A34A),
      accent:       Color(0xFF34D399),
      card:         Color(0xFF0A2B1E), // Deep pine emerald card
      cardSoft:     Color(0xFF051C13), // Forest inset
      text:         Color(0xFFECFDF5), // Mint white
      textSecondary:Color(0xFFA7F3D0), // Soft sage secondary
      border:       Color(0xFF13523B), // Pine border
      success:      Color(0xFF16A34A),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x3510B981),
      themeMode:    ThemeMode.dark,
    ),

    // 7 ── ELECTRIC (Deep Cobalt & Electric Blue Tinted Surfaces) ─────────────
    AppThemeType.electric: AppThemeConfig(
      name: 'Electric', emoji: '⚡',
      backgroundGradient: [Color(0xFF030614), Color(0xFF0E1A3D), Color(0xFF16378A)],
      sidebar:      Color(0xFF030717),
      primary:      Color(0xFF2563EB),
      primaryDark:  Color(0xFF1D4ED8),
      secondary:    Color(0xFF06B6D4),
      accent:       Color(0xFF38BDF8),
      card:         Color(0xFF0E1F42), // Deep cobalt card
      cardSoft:     Color(0xFF07122B), // Inset
      text:         Color(0xFFEFF6FF), // Electric white
      textSecondary:Color(0xFF93C5FD), // Light blue secondary
      border:       Color(0xFF1C3C78), // Cobalt border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x352563EB),
      themeMode:    ThemeMode.dark,
    ),

    // 8 ── ROYAL (Deep Velvet Purple & Imperial Tinted Surfaces) ──────────────
    AppThemeType.royal: AppThemeConfig(
      name: 'Royal', emoji: '👑',
      backgroundGradient: [Color(0xFF0B0414), Color(0xFF2C054D), Color(0xFF541258)],
      sidebar:      Color(0xFF08020F),
      primary:      Color(0xFF9333EA),
      primaryDark:  Color(0xFF7E22CE),
      secondary:    Color(0xFFC026D3),
      accent:       Color(0xFFF59E0B),
      card:         Color(0xFF240C3B), // Deep royal card
      cardSoft:     Color(0xFF170626), // Inset
      text:         Color(0xFFFAF5FF), // Pure white with violet undertone
      textSecondary:Color(0xFFD8B4FE), // Lavender secondary
      border:       Color(0xFF4C1D7D), // Imperial border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x359333EA),
      themeMode:    ThemeMode.dark,
    ),

    // 9 ── OBSIDIAN (Graphite Charcoal & Sleek Carbon Surfaces) ───────────────
    AppThemeType.obsidian: AppThemeConfig(
      name: 'Obsidian', emoji: '🖤',
      backgroundGradient: [Color(0xFF050505), Color(0xFF111111), Color(0xFF1F1F1F)],
      sidebar:      Color(0xFF0A0A0A),
      primary:      Color(0xFFE5E5E5),
      primaryDark:  Color(0xFFA3A3A3),
      secondary:    Color(0xFF737373),
      accent:       Color(0xFFFFFFFF),
      card:         Color(0xFF1A1A1A), // Sleek graphite obsidian card
      cardSoft:     Color(0xFF111111), // Carbon inset
      text:         Color(0xFFFAFAFA), // Crisp white
      textSecondary:Color(0xFFA3A3A3), // Soft light gray
      border:       Color(0xFF2E2E2E), // Subtle border
      success:      Color(0xFF22C55E),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x20FFFFFF),
      themeMode:    ThemeMode.dark,
    ),

    // 10 ── SUNSET (Deep Berry Wine & Twilight Tinted Surfaces) ────────────────
    AppThemeType.sunset: AppThemeConfig(
      name: 'Sunset', emoji: '🌅',
      backgroundGradient: [Color(0xFF140822), Color(0xFF611233), Color(0xFF8F2D07)],
      sidebar:      Color(0xFF11051D),
      primary:      Color(0xFFF43F5E),
      primaryDark:  Color(0xFFE11D48),
      secondary:    Color(0xFFF97316),
      accent:       Color(0xFFFBBF24),
      card:         Color(0xFF330E22), // Deep berry wine card
      cardSoft:     Color(0xFF210816), // Inset
      text:         Color(0xFFFFF1F2), // Rose white
      textSecondary:Color(0xFFFECDD3), // Soft blush secondary
      border:       Color(0xFF5A193D), // Twilight border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFE11D48),
      glow:         Color(0x35F43F5E),
      themeMode:    ThemeMode.dark,
    ),

    // 11 ── AURORA (Deep Northern Teal & Borealis Surfaces) ───────────────────
    AppThemeType.aurora: AppThemeConfig(
      name: 'Aurora', emoji: '🌌',
      backgroundGradient: [Color(0xFF031017), Color(0xFF073842), Color(0xFF1A1F4E)],
      sidebar:      Color(0xFF020B10),
      primary:      Color(0xFF14B8A6),
      primaryDark:  Color(0xFF0F766E),
      secondary:    Color(0xFF8B5CF6),
      accent:       Color(0xFF2DD4BF),
      card:         Color(0xFF0E2C3B), // Deep borealis teal card
      cardSoft:     Color(0xFF081C26), // Inset
      text:         Color(0xFFF0FDFA), // Mint white
      textSecondary:Color(0xFF99F6E4), // Pale teal secondary
      border:       Color(0xFF184A63), // Aurora border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x352DD4BF),
      themeMode:    ThemeMode.dark,
    ),

    // 12 ── CYBER ICE (Deep Cyan Matrix & High-Tech Glaze Surfaces) ───────────
    AppThemeType.cyberIce: AppThemeConfig(
      name: 'Cyber Ice', emoji: '🧊',
      backgroundGradient: [Color(0xFF020712), Color(0xFF082F47), Color(0xFF0E4354)],
      sidebar:      Color(0xFF01050D),
      primary:      Color(0xFF22D3EE),
      primaryDark:  Color(0xFF0891B2),
      secondary:    Color(0xFF6366F1),
      accent:       Color(0xFFA5F3FC),
      card:         Color(0xFF0B2338), // High-tech cyan-navy card
      cardSoft:     Color(0xFF061524), // Matrix inset
      text:         Color(0xFFF0FDF4), // Cyan white
      textSecondary:Color(0xFF67E8F9), // Neon cyan secondary
      border:       Color(0xFF123E61), // High-tech border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x3522D3EE),
      themeMode:    ThemeMode.dark,
    ),

    // 13 ── SOLAR (Deep Amber Espresso & Molten Bronze Surfaces) ─────────────
    AppThemeType.solar: AppThemeConfig(
      name: 'Solar', emoji: '☀️',
      backgroundGradient: [Color(0xFF120801), Color(0xFF4D220A), Color(0xFF753606)],
      sidebar:      Color(0xFF0E0501),
      primary:      Color(0xFFF59E0B),
      primaryDark:  Color(0xFFD97706),
      secondary:    Color(0xFFEA580C),
      accent:       Color(0xFFFDE68A),
      card:         Color(0xFF331707), // Deep molten bronze card
      cardSoft:     Color(0xFF210E04), // Warm dark inset
      text:         Color(0xFFFFF7ED), // Warm sun white
      textSecondary:Color(0xFFFED7AA), // Amber secondary
      border:       Color(0xFF57290C), // Molten border
      success:      Color(0xFF10B981),
      warning:      Color(0xFFD97706),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x35F59E0B),
      themeMode:    ThemeMode.dark,
    ),

    // ─────────────────────────────────────────────────────────────────────────
    // LIGHT THEMES (From Ripple ThemeConfig - Tinted Surfaces, NOT plain white)
    // ─────────────────────────────────────────────────────────────────────────

    // 14 ── LAVENDER MIST (Soft Lilac Canvas with Atmospheric Tinted Card) ─────
    AppThemeType.lavenderMist: AppThemeConfig(
      name: 'Lavender Mist', emoji: '🌸',
      backgroundGradient: [Color(0xFFFAF5FF), Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
      sidebar:      Color(0xFFF7F1FD),
      primary:      Color(0xFF7C3AED),
      primaryDark:  Color(0xFF6D28D9),
      secondary:    Color(0xFFDB2777),
      accent:       Color(0xFF4F46E5),
      card:         Color(0xFFEDE4F9), // Soft lilac tinted surface, not stark white!
      cardSoft:     Color(0xFFF6EFFD),
      text:         Color(0xFF2E1065),
      textSecondary:Color(0xFF6B21A8),
      border:       Color(0xFFD8B4FE),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x207C3AED),
      themeMode:    ThemeMode.light,
    ),

    // 15 ── NORDIC FROST (Soft Glacier Canvas with Frost Blue Tinted Card) ────
    AppThemeType.nordicFrost: AppThemeConfig(
      name: 'Nordic Frost', emoji: '🧊',
      backgroundGradient: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
      sidebar:      Color(0xFFEDF7FD),
      primary:      Color(0xFF0284C7),
      primaryDark:  Color(0xFF0369A1),
      secondary:    Color(0xFF0D9488),
      accent:       Color(0xFF6366F1),
      card:         Color(0xFFD6EEFD), // Soft glacier blue tinted surface!
      cardSoft:     Color(0xFFE5F4FE),
      text:         Color(0xFF0F172A),
      textSecondary:Color(0xFF334155),
      border:       Color(0xFF93C5FD),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x200284C7),
      themeMode:    ThemeMode.light,
    ),

    // 16 ── MINT BREEZE (Soft Spring Canvas with Mint Tinted Card) ────────────
    AppThemeType.mintBreeze: AppThemeConfig(
      name: 'Mint Breeze', emoji: '🍃',
      backgroundGradient: [Color(0xFFF0FDF4), Color(0xFFDCFCE7), Color(0xFFA7F3D0)],
      sidebar:      Color(0xFFEDFBF1),
      primary:      Color(0xFF059669),
      primaryDark:  Color(0xFF065F46),
      secondary:    Color(0xFF0284C7),
      accent:       Color(0xFF16A34A),
      card:         Color(0xFFD1FADF), // Soft mint tinted surface!
      cardSoft:     Color(0xFFE2FCEB),
      text:         Color(0xFF064E3B),
      textSecondary:Color(0xFF14532D),
      border:       Color(0xFF86EFAC),
      success:      Color(0xFF16A34A),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x20059669),
      themeMode:    ThemeMode.light,
    ),

    // 17 ── SOLAR AMBER (Warm Golden Canvas with Amber Tinted Card) ───────────
    AppThemeType.solarAmber: AppThemeConfig(
      name: 'Solar Amber', emoji: '🌾',
      backgroundGradient: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
      sidebar:      Color(0xFFFCF7E6),
      primary:      Color(0xFFD97706),
      primaryDark:  Color(0xFF92400E),
      secondary:    Color(0xFFEA580C),
      accent:       Color(0xFFDC2626),
      card:         Color(0xFFFDEBB2), // Warm butter/amber tinted surface!
      cardSoft:     Color(0xFFFEF3CB),
      text:         Color(0xFF451A03),
      textSecondary:Color(0xFF78350F),
      border:       Color(0xFFFCD34D),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFD97706),
      danger:       Color(0xFFDC2626),
      glow:         Color(0x20D97706),
      themeMode:    ThemeMode.light,
    ),

    // 18 ── ROSE SUNSET (Soft Dawn Canvas with Rose Tinted Card) ──────────────
    AppThemeType.roseSunset: AppThemeConfig(
      name: 'Rose Sunset', emoji: '🌷',
      backgroundGradient: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFECDD3)],
      sidebar:      Color(0xFFFCEDEF),
      primary:      Color(0xFFE11D48),
      primaryDark:  Color(0xFF9F1239),
      secondary:    Color(0xFFF97316),
      accent:       Color(0xFFBE185D),
      card:         Color(0xFFFED2D8), // Soft rose blush tinted surface!
      cardSoft:     Color(0xFFFEE2E6),
      text:         Color(0xFF4C0519),
      textSecondary:Color(0xFF881337),
      border:       Color(0xFFFDA4AF),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFE11D48),
      glow:         Color(0x20E11D48),
      themeMode:    ThemeMode.light,
    ),

    // 19 ── LIGHT (Crisp Modern Clean Canvas) ─────────────────────────────────
    AppThemeType.light: AppThemeConfig(
      name: 'Light Slate', emoji: '☀️',
      backgroundGradient: [Color(0xFFF8FAFC), Color(0xFFEEF2F6), Color(0xFFE2E8F0)],
      sidebar:      Color(0xFFFFFFFF),
      primary:      Color(0xFF006B5E),
      primaryDark:  Color(0xFF003730),
      secondary:    Color(0xFF3B5E8C),
      accent:       Color(0xFF9C4325),
      card:         Color(0xFFF1F5F9), // Soft slate tinted secondary surface, not stark white!
      cardSoft:     Color(0xFFE2E8F0),
      text:         Color(0xFF0F172A),
      textSecondary:Color(0xFF475569),
      border:       Color(0xFFCBD5E1),
      success:      Color(0xFF10B981),
      warning:      Color(0xFFF59E0B),
      danger:       Color(0xFFEF4444),
      glow:         Color(0x15000000),
      themeMode:    ThemeMode.light,
    ),
  };

  // ─────────────────────────────────────────────────────────────────────────
  //  PERSISTENCE & PREFERENCES
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('selected_theme');
    if (themeStr != null) {
      _currentTheme = AppThemeType.values.firstWhere(
        (e) => e.name == themeStr || e.toString().split('.').last == themeStr,
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

  Future<void> applySettingsBatch({
    required AppThemeType theme,
    required double fontSizeMultiplier,
    required String fontFamily,
    required String densityMode,
    bool animationsEnabled = true,
    required bool use24HourTime,
  }) async {
    _currentTheme = theme;
    _fontSizeMultiplier = fontSizeMultiplier;
    _fontFamily = fontFamily;
    _densityMode = densityMode;
    _animationsEnabled = animationsEnabled;
    _use24HourTime = use24HourTime;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme.name);
    await prefs.setDouble('font_size', fontSizeMultiplier);
    await prefs.setString('font_family', fontFamily);
    await prefs.setString('density_mode', densityMode);
    await prefs.setBool('animations_enabled', animationsEnabled);
    await prefs.setBool('use_24h_time', use24HourTime);
  }

  Future<void> setTheme(AppThemeType type) async {
    _currentTheme = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', type.name);
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

  ThemeData buildThemeData() {
    final config = activeThemeConfig;
    final isDark = config.isDarkTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: config.primary,
      scaffoldBackgroundColor: isDark ? const Color(0xFF030712) : const Color(0xFFF8FAFC),
      canvasColor: config.card,
      cardColor: config.card,
      dividerColor: config.border,
      fontFamily: _fontFamily == 'Default' ? null : _fontFamily,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: config.primary,
        onPrimary: Colors.white,
        secondary: config.secondary,
        onSecondary: Colors.white,
        error: config.danger,
        onError: Colors.white,
        surface: config.card,
        onSurface: config.surfaceText,
      ),
      cardTheme: CardThemeData(
        color: config.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: config.border, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: config.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.cardSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: config.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: config.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: config.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BuildContext EXTENSION  ─  usage: context.appTheme.primary
// ─────────────────────────────────────────────────────────────────────────────
extension AppThemeContext on BuildContext {
  AppThemeConfig get appTheme => ThemeManager.instance.activeThemeConfig;
}
