# Flutter Cross-Platform Screen Creation Guide
*(Updated with App Theme Colors, Responsive Best Practices, and Tablet Constraints)*

## 1. Core Principles for Cross-Platform UI
To ensure a seamless, professional experience across Mobile, Tablet, and Desktop without widget clipping, overflowing, or assertion errors, adhere to the following mandatory rules:

### A. Responsive Constraints & Breakpoints
* **Never Trust Global MediaQuery for Component Widths:** 
  In tablet or desktop mode, persistent navigation sidebars, drawers, or split-screen panels consume significant width (e.g., 300px - 420px). A tablet with a screen width of 1200px might only offer **750px - 785px** of actual content area!
  * **Rule:** Always wrap responsive sections in `LayoutBuilder` and evaluate `constraints.maxWidth` of the actual allocated content container, rather than `MediaQuery.of(context).size.width`.
* **Avoid Hardcoded Dimensions:** Never use fixed horizontal numbers (e.g. `width: 300`) that assume infinite room. Always use relative sizing, constraints, or flex factors.

### B. Prevention of RenderFlex Overflows
* **Action Bars, Toolbars & Multi-Button Rows:** 
  **NEVER** put multiple action buttons or complex segmented controls inside a rigid single horizontal `Row(children: [..., Spacer(), ...])`. In constrained containers, this WILL trigger RenderFlex horizontal overflow.
  * **Rule:** Always wrap toolbars and action controls in `Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.spaceBetween, ...)` or use `LayoutBuilder` to break them onto multiple lines gracefully when `constraints.maxWidth` is constrained.
* **Header Bars with Title & Dropdowns/Controls:**
  * When placing a title, subtitle, and selectors in a header, wrap the title/subtitle `Column` in `Expanded` or `Flexible`, and wrap the header in `LayoutBuilder` / `Wrap` so controls wrap below the title on narrow viewports rather than pushing past the screen edge.
* **Dashboard Metric / KPI Cards:**
  * Do NOT place 4 or 5 `Expanded` metric cards inside a single rigid `Row`. In a 750px viewport, each card is squashed to ~140px, causing titles to truncate (`Hea...`, `Gros...`) and numbers to break into multiple lines.
  * **Rule:** Use `LayoutBuilder` and `Wrap(spacing: 12, runSpacing: 12)` with responsive card widths:
    ```dart
    LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cardWidth = w >= 900
            ? (w - 48) / 5
            : (w >= 560 ? (w - 24) / 3 : (w - 12) / 2);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
        );
      },
    )
    ```

### C. DataTables & List Integrity
* **Strict Parity Between Columns and DataRow Cells:**
  * In Flutter, `DataTable` asserts that every row has the EXACT same number of cells as header columns (`row.cells.length == columns.length`). Missing even a single cell crashes the entire screen with a red fatal assertion screen.
  * **Rule:** Always double-check column-to-cell 1:1 mapping when adding or modifying table columns.
* **Horizontal Scrolling for Wide Tables:**
  * Always enclose `DataTable` inside `SingleChildScrollView(scrollDirection: Axis.horizontal)`.

### D. Safe Areas & Steppers
* **Steppers / Progress Indicators:**
  * Avoid redundant numbering in labels (e.g., `'1. Verification'`) when badges or icons already indicate the step index. Redundant text wastes horizontal real estate and triggers ellipses on tablets.
* **Safe Areas:** Always wrap main screen bodies in a `SafeArea` widget to prevent overlapping with status bars and navigation bars.

---

## 2. Global Design System & Theming
Centralize all colors, typography, and box decorations. **Do not hardcode styles inside individual widgets.**

### Color Palette (Hex Codes)
* **Primary Accent:** `#1DABC0` (Bright Turquoise Blue) - *Used for Headers, Primary Buttons, Active States.*
* **Background (Outer):** `#08141D` / `#F5F5F5` - *Base background for screens.*
* **Card Background:** `#0C2433` / `#FFFFFF` - *Main content containers.*
* **Card Soft / Hover:** `#103447` - *Subtle secondary containers.*
* **Border Color:** `#1A465E` / `#E2E8F0` - *Dividers & borders.*
* **Success:** `#10B981` (Emerald Green)
* **Warning / Alert:** `#F59E0B` (Amber)
* **Danger / Error:** `#EF4444` (Crimson Red)
* **Text (Primary):** `#F0FDFA` / `#1E293B`
* **Text (Secondary):** `#94A3B8` / `#64748B`

### Responsive Content Layout Helper
```dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget web; // Tablet/Desktop layout

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.web,
  });

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
```