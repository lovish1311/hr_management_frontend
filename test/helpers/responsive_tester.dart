import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_app_wrapper.dart';

class ViewportConfig {
  final String name;
  final double width;
  final double height;

  const ViewportConfig(this.name, this.width, this.height);
  Size get size => Size(width, height);
}

class ResponsiveTester {
  static const List<ViewportConfig> requiredViewports = [
    // Phone Portrait
    ViewportConfig('Phone Portrait 320x568', 320, 568),
    ViewportConfig('Phone Portrait 360x640', 360, 640),
    ViewportConfig('Phone Portrait 390x844', 390, 844),
    ViewportConfig('Phone Portrait 430x932', 430, 932),

    // Phone Landscape
    ViewportConfig('Phone Landscape 640x360', 640, 360),
    ViewportConfig('Phone Landscape 844x390', 844, 390),

    // Tablet
    ViewportConfig('Tablet 800x1280', 800, 1280),

    // Web / Desktop
    ViewportConfig('Web 1024x768', 1024, 768),
    ViewportConfig('Web 1440x900', 1440, 900),
    ViewportConfig('Web 1920x1080', 1920, 1080),
  ];

  static const List<double> requiredTextScales = [1.0, 1.5, 2.0];

  /// Tests a widget across all responsive viewports and text scales.
  /// Throws actionable errors with screen, viewport, and text scale details if overflow occurs.
  static Future<void> testScreen({
    required WidgetTester tester,
    required String screenName,
    required String route,
    required Widget Function() builder,
    List<ViewportConfig>? viewports,
    List<double>? textScales,
  }) async {
    final vps = viewports ?? requiredViewports;
    final scales = textScales ?? requiredTextScales;

    for (final vp in vps) {
      for (final scale in scales) {
        tester.view.physicalSize = Size(vp.width, vp.height);
        tester.view.devicePixelRatio = 1.0;

        final List<FlutterErrorDetails> errorList = [];
        final origOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errorList.add(details);
          origOnError?.call(details);
        };

        await tester.pumpWidget(
          TestAppWrapper.wrapWidget(
            builder(),
            size: vp.size,
            textScale: scale,
          ),
        );

        // Allow layout and microtasks to finish
        await tester.pump(const Duration(milliseconds: 100));

        final exception = tester.takeException();
        FlutterError.onError = origOnError;
        for (final err in errorList) {
          debugPrint('CAUGHT DETAILS: ${err.toString()}');
        }
        if (exception != null) {
          if (exception is FlutterError) {
            for (final d in exception.diagnostics) {
              debugPrint('DIAG: ${d.toStringDeep()}');
            }
          }
          final errorReport = [
            'FAIL:',
            'Screen: $screenName',
            'Route: $route',
            'Viewport: ${vp.name} (${vp.width}x${vp.height})',
            'Text scale: ${scale}x',
            'State: Loaded',
            'Error: $exception',
          ].join('\n');
          fail(errorReport);
        }
      }
    }

    // Reset tester view size
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
}
