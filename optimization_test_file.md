# Physical Device Optimization & Automation Test Manifesto
> **Document Purpose**: Production validation runbook designed for automated execution by the AI agent on a physical Android device (or physical emulator) to verify frontend speed optimizations, skeleton placeholders, zero RenderFlex overflows, dynamic strings, and 60 FPS frame budgets on narrow small-phone viewports (360x640 dp / 320 dpi).

---

## 1. Automation Infrastructure & ADB Tooling

The AI agent executes these test cases autonomously using Android Debug Bridge (`adb`).

### 1.1 Device Pre-Flight Commands
```bash
# 1. Verify physical device connection
adb devices

# 2. Reverse proxy backend port 8080 to physical mobile over USB
adb reverse tcp:8080 tcp:8080

# 3. Clear existing logcat buffers before test session
adb logcat -c

# 4. Enable GPU Profile rendering bars (On-Screen Telemetry)
adb shell setprop debug.hwui.profile visual_bars

# 5. Reset gfxinfo framestats buffer
adb shell dumpsys gfxinfo com.example.hr_management reset
```

### 1.2 Agent Telemetry & Inspection Primitives
| Operation | Command | Expected Output / Assertion |
| :--- | :--- | :--- |
| **Overflow Audit** | `adb logcat -d | Select-String "A RenderFlex overflowed"` | **0 matches** (Strict zero-overflow pass). |
| **FPS / Frame Budget** | `adb shell dumpsys gfxinfo com.example.hr_management` | Janky frames < 2%, 90th percentile < 16.6ms. |
| **Visual Capture** | `adb exec-out screencap -p > test_artifact.png` | Screen capture saved for visual verification. |
| **Tap Element** | `adb shell input tap <X> <Y>` | Triggers UI interaction. |
| **Fling / Scroll** | `adb shell input swipe <X> <Y1> <X> <Y2> 250` | Smooth physics-based fling list traversal. |

---

## 2. Test Suite: Automated Test Cases

---

### TC-OPT-01: Employee Home Screen — Zero Clock Rebuilds & Small-Phone Geometry
- **Target File**: [employee_home_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/home/presentation/pages/employee_home_page.dart)
- **Features Tested**: Elimination of 1-second `_clockTimer`, isolated `_LiveSunClockShiftCard` (30s timer), 14dp responsive screen padding, sun circle 66x66 geometry.
- **Pre-Conditions**: User logged in as regular employee (`lovish@company.com` / `user123`).

#### Agent Execution Steps:
1. Launch app and ensure landing on `/home`:
   ```bash
   adb shell input tap 180 320
   ```
2. Capture screenshot to verify layout geometry:
   ```bash
   adb exec-out screencap -p > tc01_home_layout.png
   ```
3. **Telemetry & CPU Idle Test**:
   - Keep screen idle on `/home` for 10 seconds.
   - Run dumpsys framestats:
     ```bash
     adb shell dumpsys gfxinfo com.example.hr_management framestats
     ```
   - **Assertion**: When the screen is idle, zero continuous frame draws occur. The clock is isolated to a 30s child timer; the parent `EmployeeHomePage` rebuild counter is **0 per second** (eliminating 3,600 full-tree rebuilds/hour).
4. **Visual Proportions Check**:
   - Verify greeting header font is cleanly fitted (`20pt` on small screens).
   - Verify sun clock circle is compact (`66x66 dp`) and does not push the shift timings text ("Monday | 10:00 AM To 19:00 PM Shift") off screen or into awkward multi-line wraps.
   - Verify outer horizontal margins are `14dp` instead of oversized `20dp`.

---

### TC-OPT-02: HR Dashboard — Dynamic Strings, Date Header & Shimmer Skeletons
- **Target File**: [dashboard_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/dashboard/presentation/pages/dashboard_page.dart)
- **Features Tested**: Live date formatting `_formatCurrentDate()`, dynamic greeting `Good ${_getGreeting()}, ${_getDisplayName()} 👋`, [dashboard_skeleton.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/dashboard/presentation/widgets/dashboard_skeleton.dart).
- **Pre-Conditions**: User logged in as HR / Super Admin (`admin@company.com` / `admin123`).

#### Agent Execution Steps:
1. Tap the drawer menu button or navigate to `/dashboard`:
   ```bash
   adb shell input tap 40 50
   ```
2. Trigger hard refresh to observe loading state:
   ```bash
   # Tap refresh icon on top AppBar
   adb shell input tap 310 50
   ```
3. Immediately capture screenshot within 300ms of refresh:
   ```bash
   adb exec-out screencap -p > tc02_dashboard_skeleton.png
   ```
4. **Visual Assertions**:
   - **Skeleton Check**: Verify shimmering hero banner, 2-column KPI card skeletons, and quick action placeholders render during data fetch. **NO raw circular progress spinner** in the center.
   - **Date Assertion**: Top AppBar pill displays today's live weekday and date (e.g. `Monday, Oct 12`), NOT the static string `"Friday, Aug 21"`.
   - **Greeting Assertion**: Banner greets the authenticated user dynamically (e.g. `Good Morning, Admin 👋` or `Good Afternoon, Lovish 👋`), NOT `"Good Morning, HR Team 👋"`.
   - **KPI Card Layout**: Verify KPI cards render in a balanced 2-column mobile grid with zero text clipping.

---

### TC-OPT-03: Attendance Calendar — $O(1)$ Lookup, Repaint Boundaries & Skeleton Grid
- **Target File**: [attendance_calendar_grid.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/attendance/presentation/widgets/attendance_calendar_grid.dart) & [attendance_calendar_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/attendance/presentation/pages/attendance_calendar_page.dart)
- **Features Tested**: $O(1)$ `dayMap` indexing, cell-level `RepaintBoundary` isolation, `AttendanceCalendarSkeleton` (35 day cells placeholder), elimination of 35 running animation tickers.

#### Agent Execution Steps:
1. Navigate to `/attendance` from drawer:
   ```bash
   adb shell input tap 40 50
   adb shell input tap 120 220
   ```
2. Capture screenshot during month transition:
   ```bash
   # Tap chevron to change month (triggers loading)
   adb shell input tap 50 180
   adb exec-out screencap -p > tc03_attendance_skeleton.png
   ```
3. **Skeleton Verification**:
   - Verify the 35-cell grid skeleton appears with shimmering rounded rectangles during monthly punch loading. The page layout remains locked in place without jumping down.
4. **Scroll & Tap Interaction Performance**:
   - Rapidly swipe through the calendar and tap date cells:
     ```bash
     adb shell input swipe 180 500 180 200 150
     adb shell input tap 180 350
     ```
   - Check gfxinfo frame rendering time:
     ```bash
     adb shell dumpsys gfxinfo com.example.hr_management | Select-String "Janky frames"
     ```
   - **Assertion**: Janky frames < 2%. Because each cell is wrapped in `RepaintBoundary`, tapping or hovering on Day 15 repaints **only that single cell**, rather than triggering a full canvas raster invalidation for all 35 day cells.

---

### TC-OPT-04: Holiday Calendar — Shimmer List & Small-Phone 14dp Padding
- **Target File**: [holiday_calendar_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/holidays/presentation/pages/holiday_calendar_page.dart)
- **Features Tested**: [holiday_skeleton.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/holidays/presentation/widgets/holiday_skeleton.dart) (6 shimmering rows), responsive padding (`14.0` vs `24.0`).

#### Agent Execution Steps:
1. Navigate to `/holidays`:
   ```bash
   adb shell input tap 40 50
   adb shell input tap 120 320
   ```
2. Trigger refresh:
   ```bash
   adb shell input tap 310 50
   adb exec-out screencap -p > tc04_holidays_skeleton.png
   ```
3. **Assertions**:
   - 6 shimmering holiday placeholder rows appear instantly with avatar box and text placeholders.
   - Screen padding fits snugly on 360dp width without leaving cramped margins.
   - Filter pills ("All Holidays", "General", "Restricted") fit on screen and switch instantly without frame stutters.

---

### TC-OPT-05: Tambola Game Zone — Polling Suppression & Dynamic Room Titles
- **Target File**: [tambola_game_room_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/tambola/presentation/pages/tambola_game_room_page.dart) & [tambola_lobby_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/tambola/presentation/pages/tambola_lobby_page.dart)
- **Features Tested**: Polling condition `!_socketService.isConnected`, dynamic lobby weekday hint, dynamic lounge title.

#### Agent Execution Steps:
1. Navigate to `/tambola`:
   ```bash
   adb shell input tap 40 50
   adb shell input tap 120 480
   ```
2. Inspect lobby screen:
   ```bash
   adb exec-out screencap -p > tc05_tambola_lobby.png
   ```
3. **Visual Assertions**:
   - Title displays dynamically: e.g. `"Lovish Tambola Lounge 🎉"` or `"TeamJoy Tambola Lounge 🎉"`, NOT `"HR Team Tambola Lounge 🎉"`.
   - Tap "Host New Game" modal button:
     ```bash
     adb shell input tap 180 280
     ```
   - Input hint displays: `"e.g. Monday Fun Tambola"` (reflecting current weekday), NOT static `"Friday Fun Tambola"`.
4. **WebSocket Suppression Assertion**:
   - Join room `DEMO1`.
   - Monitor logcat for 20 seconds:
     ```bash
     adb logcat -d | Select-String "GET /api/v1/games/tambola"
     ```
   - **Assertion**: When WebSocket is connected, **zero periodic HTTP polling GET requests are dispatched**. Polling is strictly suppressed as long as `_socketService.isConnected == true`.

---

### TC-OPT-06: Small-Phone RenderFlex Zero-Overflow Audit Across All Screens
- **Target**: Comprehensive scan across all application pages on physical viewport (360x640 dp).

#### Agent Execution Steps:
1. Run automated navigation loop across all 5 major routes (`/home`, `/dashboard`, `/attendance`, `/holidays`, `/tambola`):
   ```bash
   adb logcat -c
   # Navigate through screens sequentially...
   ```
2. Query logcat for any RenderFlex error signatures:
   ```bash
   adb logcat -d | Select-String -Pattern "overflowed by", "RenderFlex"
   ```
3. **Strict Gate Condition**:
   - **PASS**: 0 matches found.
   - **FAIL**: Any instance of `A RenderFlex overflowed by X pixels`.

---

### TC-OPT-07: Employee Directory & Cards — Clean Enums & Small-Phone Geometry
- **Target Files**: [employee_directory_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/employees/presentation/pages/employee_directory_page.dart) & [employee_card.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/employees/presentation/widgets/employee_card.dart)
- **Features Tested**: Formatted human-readable roles (`_formatRole` removes `ROLE_` prefix), title-case status labels ('Active', 'Probation', 'Notice Period', 'Inactive', 'Present', 'Late', 'On Leave', 'Absent'), responsive grid extent (`(180.0 + (textScale - 1.0) * 120).clamp(180.0, 320.0)`), and `EmployeeGridSkeleton`.
- **Pre-Conditions**: User logged in (`admin@company.com` or `lovish@company.com`).

#### Agent Execution Steps:
1. Navigate to `/employees`:
   ```bash
   adb shell input tap 40 50
   adb shell input tap 120 140
   ```
2. Capture screenshot of employee cards:
   ```bash
   adb exec-out screencap -p > tc07_employee_cards.png
   ```
3. **Assertions**:
   - Verify all role badges display clean titles (e.g. "Super Admin", "Software Engineer"), with **zero raw enum names** like `ROLE_SUPER_ADMIN`.
   - Verify status badges display title case (e.g. "Active", "Probation", "On Leave"), never raw uppercase `ON_LEAVE`.
   - Verify employee cards fit neatly on 360dp width with 14dp spacing and zero RenderFlex overflow.

---

### TC-OPT-08: Leave Management — Responsive TabBar, Quota Grid & 96dp FAB Clearance
- **Target File**: [leave_management_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/leaves/presentation/pages/leave_management_page.dart)
- **Features Tested**: Compact 38dp TabBar, 96dp bottom padding clearing FAB, `_QuotaCardTile` responsive padding (`10.0/8.0dp`) and `FittedBox` scale down for numbers.

#### Agent Execution Steps:
1. Navigate to `/leaves`:
   ```bash
   adb shell input tap 40 50
   adb shell input tap 120 280
   ```
2. Capture dashboard view and scroll down to bottom:
   ```bash
   adb exec-out screencap -p > tc08_leaves_dashboard.png
   adb shell input swipe 180 500 180 150 250
   adb exec-out screencap -p > tc08_leaves_bottom_fab.png
   ```
3. **Assertions**:
   - Verify TabBar fits neatly without text clipping.
   - Verify quota cards display remaining balances clearly without overflowing vertically.
   - Verify bottom-most cards are fully visible above the floating action button thanks to 96dp clearance.

---

### TC-OPT-09: Apply Leave Dialog — Dynamic Manager Resolution & Small-Phone Protection
- **Target File**: [apply_leave_dialog.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/leaves/presentation/widgets/apply_leave_dialog.dart)
- **Features Tested**: Dynamic manager name and initials resolution, `Flexible` text column with ellipsis to prevent horizontal RenderFlex overflow on narrow screens.

#### Agent Execution Steps:
1. Open the Apply Leave dialog by tapping the FAB:
   ```bash
   adb shell input tap 310 580
   ```
2. Capture dialog screenshot:
   ```bash
   adb exec-out screencap -p > tc09_apply_leave_dialog.png
   ```
3. **Assertions**:
   - Verify reporting manager chip shows dynamic manager name (`Harsh Kaushal` or assigned lead) with initials circle.
   - Zero RenderFlex overflows across session selectors, date pickers, or reason fields.

---

### TC-OPT-10: Monthly Payroll Inputs & LOP — Desktop Disclaimer & Responsive Geometry
- **Target File**: [monthly_payroll_inputs_screen.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/payroll/presentation/screens/monthly_payroll_inputs_screen.dart)
- **Features Tested**: Desktop recommended disclaimer banner, responsive filter header padding (`isCompact ? 12 : 20`), compact buttons (`Size(isCompact ? 0 : 120, isCompact ? 36 : 40)`), responsive table container padding (`isSmall ? 10 : 20`).

#### Agent Execution Steps:
1. Navigate to `/payroll_inputs`:
   ```bash
   adb shell input tap 40 50
   adb shell input swipe 180 500 180 200 250
   adb shell input tap 120 450
   ```
2. Capture payroll inputs screen:
   ```bash
   adb exec-out screencap -p > tc10_payroll_inputs.png
   ```
3. **Assertions**:
   - Top banner clearly displays: *"Desktop Recommended: Multi-column payroll calculation matrices, LOP day inputs, and attendance batch sync are optimized for desktop & laptop displays."*
   - Filter chips and search bar wrap neatly without causing horizontal screen clipping.

---

### TC-OPT-11: Payslip Screen — Shimmer Skeletons & Responsive Stats
- **Target File**: [payslip_screen.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/payroll/presentation/screens/payslip_screen.dart)
- **Features Tested**: `PayslipSkeletonLoader` shimmer, `FittedBox` formatted currency cards, responsive header.

#### Agent Execution Steps:
1. Navigate to `/payslip`:
   ```bash
   adb shell input tap 40 50
   adb shell input tap 120 400
   ```
2. Capture payslip screen:
   ```bash
   adb exec-out screencap -p > tc11_payslip_screen.png
   ```
3. **Assertions**:
   - Shimmer placeholder renders during data load.
   - YTD take-home amounts fit cleanly without truncation.

---

### TC-OPT-12: Settings Page — Cached `_hasChanges` & Responsive Theme Cards
- **Target File**: [settings_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/settings/presentation/pages/settings_page.dart)
- **Features Tested**: Cached `_hasChangesCached` computation, responsive padding (`isSmallScreen ? 14 : 24`), loading state spinner in Apply button.

#### Agent Execution Steps:
1. Navigate to `/settings`:
   ```bash
   adb shell input tap 40 50
   adb shell input swipe 180 500 180 150 250
   adb shell input tap 120 520
   ```
2. Capture settings screen:
   ```bash
   adb exec-out screencap -p > tc12_settings_page.png
   ```
3. **Assertions**:
   - Theme preview cards render cleanly on 360dp width.
   - Floating action bar at bottom adapts smoothly to compact mode.

---

### TC-OPT-13: Authentication / Login Page — Small-Phone Geometry & Lovish Credentials
- **Target File**: [login_page.dart](file:///c:/Users/Lovish/Projects/hr_management_frontend/lib/features/auth/presentation/pages/login_page.dart)
- **Features Tested**: FittedBox scale-down for 1-tap demo preset buttons, updated Lovish credentials (`lovish@company.com` / `user123`).

#### Agent Execution Steps:
1. Navigate to `/login` (or logout):
   ```bash
   adb shell input tap 40 50
   adb shell input swipe 180 500 180 150 250
   adb shell input tap 120 580
   ```
2. Capture login page:
   ```bash
   adb exec-out screencap -p > tc13_login_page.png
   ```
3. **Assertions**:
   - Tap "Lovish (Emp)" preset button: fills `lovish@company.com` and `user123`.
   - Preset buttons never clip or wrap awkwardly on 360dp width.

---

## 3. Automated Agent Execution Script

When the user asks you to *"execute the optimization tests on the physical device"*, execute this sequence covering Group A and Group B:

```powershell
Write-Host "=== Starting Physical Device Optimization Test Automation ===" -ForegroundColor Cyan

# Step 1: Device connectivity & ADB reverse
adb devices
adb reverse tcp:8080 tcp:8080
adb logcat -c

# Step 2: Clear and reset framestats telemetry
adb shell dumpsys gfxinfo com.example.hr_management reset

# Step 3: Capture Group A Screens (Home, Dashboard, Attendance, Holidays, Tambola)
adb shell input tap 180 320
Start-Sleep -Seconds 2
adb exec-out screencap -p > C:\Users\Lovish\Projects\docs\test_home_360dp.png

adb shell input tap 40 50
Start-Sleep -Milliseconds 600
adb shell input tap 120 180
Start-Sleep -Seconds 2
adb exec-out screencap -p > C:\Users\Lovish\Projects\docs\test_dashboard_dynamic.png

adb shell input tap 40 50
Start-Sleep -Milliseconds 600
adb shell input tap 120 220
Start-Sleep -Seconds 2
adb exec-out screencap -p > C:\Users\Lovish\Projects\docs\test_attendance_grid.png

# Step 4: Capture Group B Screens (Employees, Leaves, Payroll, Settings)
adb shell input tap 40 50
Start-Sleep -Milliseconds 600
adb shell input tap 120 140
Start-Sleep -Seconds 2
adb exec-out screencap -p > C:\Users\Lovish\Projects\docs\test_employees_360dp.png

adb shell input tap 40 50
Start-Sleep -Milliseconds 600
adb shell input tap 120 280
Start-Sleep -Seconds 2
adb exec-out screencap -p > C:\Users\Lovish\Projects\docs\test_leaves_360dp.png

# Step 5: Verify Zero RenderFlex Overflows Across All Routes
$overflows = adb logcat -d | Select-String -Pattern "overflowed by", "RenderFlex"
if ($overflows.Count -eq 0) {
    Write-Host "✅ OVERFLOW AUDIT PASSED: Zero RenderFlex overflows detected across all routes!" -ForegroundColor Green
} else {
    Write-Host "❌ OVERFLOW AUDIT FAILED: Detected $($overflows.Count) layout overflows!" -ForegroundColor Red
    $overflows | ForEach-Object { Write-Host $_.Line -ForegroundColor Yellow }
}

# Step 6: Telemetry Dump
Write-Host "=== Telemetry Framestats ===" -ForegroundColor Cyan
adb shell dumpsys gfxinfo com.example.hr_management | Select-String "Janky frames", "50th percentile", "90th percentile", "99th percentile"
```
