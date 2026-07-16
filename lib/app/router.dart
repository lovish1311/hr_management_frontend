import 'package:flutter/material.dart';

// Package: hr_management

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => const Scaffold(
            body: Center(
              child: Text('HR Management App Dashboard'),
            ),
          ),
    };
  }
}
