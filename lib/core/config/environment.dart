import 'package:flutter/foundation.dart';

/// Centralized Environment and Application Configuration.
/// Handles compile-time overrides, branding, and environment-aware flags.
class Environment {
  /// Whether the application is running in production mode.
  /// Defaults to [kReleaseMode] unless explicitly overridden via compile-time flag.
  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION', defaultValue: kReleaseMode);

  /// Brand name of the organization / company.
  static const String companyName = String.fromEnvironment('COMPANY_NAME', defaultValue: 'HR Management');

  /// Master administrator email for root-level authority checks.
  static const String masterAdminEmail = String.fromEnvironment('MASTER_ADMIN_EMAIL', defaultValue: 'admin@company.com');

  /// Domain used for company email addresses.
  static const String emailDomain = String.fromEnvironment('EMAIL_DOMAIN', defaultValue: 'company.com');

  /// Corporate headquarters address.
  static const String companyAddress = String.fromEnvironment(
    'COMPANY_ADDRESS',
    defaultValue: 'Cyber Hub, Tower B, Phase 2, Gurugram, India',
  );

  /// Default physical office location name.
  static const String defaultLocation = String.fromEnvironment('DEFAULT_LOCATION', defaultValue: 'Main Office');

  /// Currency code (e.g. INR, USD, EUR).
  static const String currencyCode = String.fromEnvironment('CURRENCY_CODE', defaultValue: 'INR');

  /// Currency display symbol (e.g. ₹, $, €).
  static const String currencySymbol = String.fromEnvironment('CURRENCY_SYMBOL', defaultValue: '₹');

  /// Currency name in words for legal financial documents (e.g. Rupees, Dollars).
  static const String currencyName = String.fromEnvironment('CURRENCY_NAME', defaultValue: 'Rupees');

  /// Whether demo quick-fill presets and developer test shortcuts should be shown.
  /// Strictly false in production mode.
  static bool get showDemoPresets => !isProduction && kDebugMode;
}
