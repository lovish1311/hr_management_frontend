# HR Employee Section - Development Plan & Status

## 1. Deep Image Analysis & Visualization

Based on the provided mockups, the Employee section consists of two primary views for the HR persona:

### View A: Employee Directory (List View)
*   **Layout**: A main dashboard area with a top search bar, a row of filter pills, and a responsive grid of employee cards.
*   **Top Bar**:
    *   Search input field ("Search by name, role...").
    *   Primary action button: "+ Add Employee".
*   **Filters**:
    *   Horizontal scrollable list of pills: "All" (default active), "Engineering", "Design", "Manager", "Marketing", "Finance", "HR".
*   **Content**:
    *   Count indicator ("Total: 142 Employees").
    *   **Employee Card Widget**:
        *   White card with subtle shadow and rounded corners.
        *   Top-right context menu (3 dots).
        *   Centered 3D Avatar Image.
        *   Employee Name (Bold).
        *   Role (Grey text).
        *   Status indicator pill (e.g., "Active" in green).

### View B: Employee Profile (Detailed View)
*   **Layout**: A split-pane view (on desktop). Left side is a fixed summary card, right side contains tabbed detailed information. The sidebar collapses to icons only to give more space.
*   **Left Column (Summary Card)**:
    *   Large 3D Avatar.
    *   Name and "Role | Department".
    *   "Direct Manager" section with manager name and small avatar.
    *   Contact Info: Email and Phone with respective icons.
    *   "Quick Links": Edit Profile, Emergency Info.
*   **Right Column (Details Area)**:
    *   **Tabs**: Profile Details, Attendance, Leaves, Performance.
    *   **Profile Details Tab**:
        *   "Personal Information" section with field-value pairs styled as labels above grey read-only input boxes (Employee ID, Department, Role, Date of Birth, Location).
        *   "Emergency Contact" section with similar fields.
    *   **Stats Cards**: Bottom area shows summary metrics:
        *   "Attendance Rate" (Green box with percentage and mini bar chart).
        *   "Leave Balance" (Blue box with days and mini bar chart).

## 2. Requirements

### Assets & Images
*   **3D Avatars**: The design heavily relies on 3D character avatars. 
    *   *Requirement*: We need a set of 3D avatar images. Until these are provided by a designer, we can generate some placeholder images or use Flutter's `CircleAvatar` with initials/standard icons.
*   **Icons**: Standard Material icons can be used for email, phone, search, notifications, etc.

### UI Components Needed
*   `CustomSearchBar`
*   `FilterPillList` & `FilterPill`
*   `EmployeeGridCard`
*   `ProfileSummaryCard`
*   `ReadOnlyField` (for the grey input boxes)
*   `MiniStatCard` (for Attendance Rate and Leave Balance)
*   Collapsible Sidebar variant (or update the existing `HrDrawer` to support an icon-only mode).

### Data Models & Backend
*   **Employee Entity**: Needs fields for ID, Name, Role, Department, Status, Avatar URL, Email, Phone, Manager ID, Date of Birth, Location, Emergency Contact Info, Attendance Rate, Leave Balance.

## 3. Status Tracking (Updates)

### What has been done
*   [x] Initial visualization and requirements breakdown completed.
*   [x] Created this markdown file to track progress.

### What needs to be done
*   [ ] **Setup**: Create `lib/features/employees/` directory structure (presentation, domain, data).
*   [ ] **Routing**: Add routes in `app/router.dart` for `/employees` and `/employee_profile`.
*   [ ] **Navigation**: Update the existing `HrDrawer` to link to the new `/employees` route and handle active state highlighting.
*   [ ] **UI - Directory Page**: Build the top bar, filter list, and the responsive `GridView` for employee cards.
*   [ ] **UI - Profile Page**: Build the split layout, summary card, tab bar, and profile details fields.
*   [ ] **Mock Data**: Create a dummy data provider to populate the UI before backend integration.
*   [ ] **Assets**: Add placeholder avatars to `assets/images/` and update `pubspec.yaml`.

### What to remove/refactor
*   [ ] The current `HrDrawer` needs refactoring to support the collapsed "icon-only" state seen in the Employee Profile view, or we need to design the layout to automatically handle this responsiveness.
