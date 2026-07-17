# Flutter Cross-Platform Screen Creation Guide
*(Updated with App Theme Colors and Responsive Best Practices)*

## 1. Core Principles for Cross-Platform UI
To ensure a seamless experience across iOS, Android, and Web without widget sizing issues, adhere to the following responsive design rules:

* **Avoid Hardcoded Dimensions:** Never use fixed numbers for heights or widths (e.g., `width: 300`). Always use relative sizing, constraints, or flex factors.
* **Use `LayoutBuilder` & `MediaQuery`:** Use `MediaQuery.of(context).size` to get screen dimensions and `LayoutBuilder` to adapt widgets based on parent constraints.
* **Prevent Overflow:** Always wrap heavily nested `Row` or `Column` children in `Expanded` or `Flexible` widgets.
* **Web/Tablet Adaptability:** Use a `ResponsiveBuilder` (or a custom wrapper class) to render a distinct layout for Web/Desktop (e.g., side navigation instead of bottom navigation) if the screen width exceeds a certain breakpoint (e.g., 800px).
* **Safe Areas:** Always wrap main screen bodies in a `SafeArea` widget to prevent overlapping with device notches, status bars, and home indicators.

---

## 2. Global Design System & Theming
Centralize all colors, typography, and box decorations. **Do not hardcode styles inside individual widgets.**

### Color Palette (Hex Codes)
* **Primary Accent:** `#1DABC0` (Bright Turquoise Blue) - *Used for Headers, Primary Buttons, Active States.*
* **Background (Outer):** `#F5F5F5` - *Base background for screens.*
* **Card Background (White):** `#FFFFFF` - *Main content containers.*
* **Accent Card 1 (Blue):** `#E0F7FA` - *Specific dashboard modules.*
* **Accent Card 2 (Green):** `#E8F5E9` - *Specific dashboard modules (e.g., achievements, success states).*
* **Text (Primary):** `#333333` - *Headings.*
* **Text (Secondary):** `#444444` - *Body text.*

### Color Palette File
The global design system colors are implemented in [colors.dart](file:///c:/Users/Lovish/flutter-projects/hr_management/lib/core/constants/colors.dart). Feel free to import it in your widgets and themes.
 

 import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget web; // Tablet/Desktop layout

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    required this.web,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return web;
        } else {
          return mobile;
        }
      },
    );
  }
}