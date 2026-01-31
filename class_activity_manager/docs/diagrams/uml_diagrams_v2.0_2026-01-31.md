# Class Activity Manager - UML Diagrams (Delta v2.0)

**Version:** 2.0
**Date:** 2026-01-31
**Based on:** v0.1.1 UI Revamp
**Baseline:** v1.0 (2026-01-30)

> This document contains ONLY changes from v1.0.
> See `uml_diagrams_v1.0_2026-01-30.md` for complete baseline documentation.

---

## Table of Contents

1. [Domain Model Changes](#1-domain-model-changes)
2. [New Use Cases](#2-new-use-cases)
3. [Modified Use Cases](#3-modified-use-cases)
4. [New Sequence Diagrams](#4-new-sequence-diagrams)
5. [New Components](#5-new-components)
6. [Navigation Changes](#6-navigation-changes)

---

## 1. Domain Model Changes

### 1.1 Group Model - New Fields

The `Group` model has been extended with two new fields:

```
+============================+
|     Group (v2.0)           |
+============================+
| - id: String               |
| - name: String             |
| - notes: String?           |
| - academicYearId: String?  |
| + moduleIds: List<String>  |  <-- NEW: Many-to-many with Modul
| + color: String?           |  <-- NEW: Hex color (e.g., "#4CAF50")
+============================+
```

**New Fields:**
- `moduleIds` (List<String>): IDs of modules taught to this group
- `color` (String?): Hex color code for calendar visualization

### 1.2 New Relationship: Group ↔ Modul

```
+===========================================================================+
|                    NEW RELATIONSHIP: Group - Modul                         |
+===========================================================================+

+-------------------+                           +-------------------+
|      Group        |                           |      Modul        |
+-------------------+         *     *           +-------------------+
| - moduleIds:      |-------------------------->| - id: String      |
|     List<String>  |    (many-to-many via      | - code: String    |
|                   |     Group.moduleIds)      | - name: String    |
+-------------------+                           +-------------------+

This relationship enables:
- One group can be assigned multiple modules
- One module can be taught to multiple groups
- Dashboard and Calendar can query active RAs per group
```

### 1.3 Updated State Container

```
+---------------------------+
|     AppState (v2.0)       |
+---------------------------+
| - currentYear:            |
|     AcademicYear?         |
| - recurringHolidays:      |
|     List<RecurringHoliday>|
| - groups: List<Group>     | <-- Groups now have moduleIds and color
| - moduls: List<Modul>     |
| - selectedCicleIds:       |
|     List<String>          |
| - dailyNotes:             |
|     List<DailyNote>       |
+---------------------------+
```

---

## 2. New Use Cases

### UC17 - Assign Color to Group

| Field | Description |
|-------|-------------|
| **ID** | UC17 |
| **Name** | Assign Color to Group |
| **Status** | NEW |
| **Actor** | Teacher |
| **Precondition** | None |
| **Main Flow** | 1. Teacher navigates to group form (new or edit)<br>2. Teacher views color palette with 8 preset colors<br>3. Teacher taps desired color circle<br>4. Selected color shows checkmark and glow<br>5. Teacher saves group |
| **Postcondition** | Group.color is set to hex value (e.g., "#4CAF50") |
| **Notes** | Color is used in Calendar and Dashboard to identify group sessions |

**Preset Colors:**
- Green (#4CAF50), Blue (#2196F3), Orange (#FF9800), Purple (#9C27B0)
- Red (#F44336), Cyan (#00BCD4), Brown (#795548), Blue Grey (#607D8B)

---

### UC18 - View Calendar

| Field | Description |
|-------|-------------|
| **ID** | UC18 |
| **Name** | View Calendar |
| **Status** | NEW |
| **Actor** | Teacher |
| **Precondition** | Groups exist with moduleIds, RAs have dates configured |
| **Main Flow** | 1. Teacher navigates to /calendar<br>2. System displays monthly calendar grid<br>3. Days with scheduled RAs show colored dots<br>4. Teacher clicks a day<br>5. Right panel shows sessions for that day<br>6. Teacher can click "Anar a notes diàries" to navigate |
| **Postcondition** | None (read-only view) |
| **Notes** | Color dots match group colors; multiple groups show multiple dots |

---

### UC19 - Select Date Range (Dual Calendar)

| Field | Description |
|-------|-------------|
| **ID** | UC19 |
| **Name** | Select Date Range |
| **Status** | NEW |
| **Actor** | Teacher |
| **Precondition** | RA configuration dialog is open |
| **Main Flow** | 1. Teacher clicks date range selector in RA config<br>2. System shows DualDatePicker dialog<br>3. Left calendar selects start date<br>4. Right calendar selects end date<br>5. Validation ensures end >= start<br>6. Teacher clicks "Confirmar"<br>7. Dialog returns DateTimeRange |
| **Postcondition** | Date range returned to calling component |
| **Notes** | Replaces sequential date pickers for better UX |

---

## 3. Modified Use Cases

### UC08 - Configure RA Dates (Modified)

| Field | v1.0 | v2.0 |
|-------|------|------|
| **Main Flow Step 4** | Teacher selects start date via date picker | Teacher clicks date range card |
| **Main Flow Step 5** | Teacher selects end date via date picker | DualDatePicker shows two side-by-side calendars |
| **Main Flow Step 6** | — | Teacher selects start (left) and end (right) dates simultaneously |
| **Main Flow Step 7** | — | Teacher clicks "Confirmar" |
| **UI Component** | showDatePicker × 2 | DualDatePicker.show() |

---

### UC14 - Create Group (Modified)

| Field | v1.0 | v2.0 |
|-------|------|------|
| **Form Fields** | name, notes | name, notes, **color**, **moduleIds** |
| **Main Flow Step 3** | Teacher fills name and notes | Teacher fills name, notes, selects color, selects modules |
| **Postcondition** | Group created with name/notes | Group created with color and module associations |

**New Form Sections:**
1. Color selection - 8 preset colors in circular palette
2. Module assignment - Checkbox list of available modules

---

### UC16 - View Dashboard (Modified)

| Field | v1.0 | v2.0 |
|-------|------|------|
| **Content** | Basic welcome message | Active RAs grid + Today's sessions |
| **Sections** | 1 (Welcome) | 2 (Today's Classes, Active RAs) |
| **Data Shown** | None | Group-Module-RA with progress bars |

**New Dashboard Sections:**
1. **Today's Classes** - Cards showing sessions active today
2. **Active RAs Grid** - Responsive grid (1-4 columns) showing all RAs in progress

---

## 4. New Sequence Diagrams

### 4.1 UC17 - Assign Color to Group

```
+===========================================================================+
|           SEQUENCE DIAGRAM: UC17 - Assign Color to Group                   |
+===========================================================================+

  Teacher           GroupFormPage                          AppStateNotifier       AppState
     |                    |                                      |                   |
     |  Navigate to       |                                      |                   |
     |  /grups/new        |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |  Display form      |                                      |                   |
     |  with color        |                                      |                   |
     |  palette           |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
     |  Tap color circle  |                                      |                   |
     |  (e.g., #4CAF50)   |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  setState(() =>                      |                   |
     |                    |    _selectedColor = hex)             |                   |
     |                    |----------+                           |                   |
     |                    |          |                           |                   |
     |  Show checkmark    |<---------+                           |                   |
     |  on selected       |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
     |  Click "Desa"      |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  addGroup(Group(                     |                   |
     |                    |    ..., color: _selectedColor))      |                   |
     |                    |------------------------------------->|                   |
     |                    |                                      |                   |
     |                    |                                      |  Add group with   |
     |                    |                                      |  color to state   |
     |                    |                                      |------------------>|
     |                    |                                      |                   |
     |  Navigate to       |                                      |                   |
     |  /grups            |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
```

---

### 4.2 UC08 (v2) - Configure RA Dates with Dual Calendar

```
+===========================================================================+
|     SEQUENCE DIAGRAM: UC08 (v2) - Configure RA Dates with Dual Calendar    |
+===========================================================================+

  Teacher          RaConfigPage         DualDatePicker       AppStateNotifier       AppState
     |                    |                    |                      |                   |
     |  Click edit on     |                    |                      |                   |
     |  specific RA       |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Display dialog    |                    |                      |                   |
     |  with date card    |                    |                      |                   |
     |<-------------------|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Tap date range    |                    |                      |                   |
     |  card              |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |                    |  DualDatePicker    |                      |                   |
     |                    |  .show()           |                      |                   |
     |                    |------------------->|                      |                   |
     |                    |                    |                      |                   |
     |  Display dual      |                    |                      |                   |
     |  calendar dialog   |                    |                      |                   |
     |<------------------------------------|                      |                   |
     |                    |                    |                      |                   |
     |  Select start date |                    |                      |                   |
     |  (left calendar)   |                    |                      |                   |
     |----------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |                    |                    |  setState()          |                   |
     |                    |                    |  _startDate = date   |                   |
     |                    |                    |----------+           |                   |
     |                    |                    |          |           |                   |
     |                    |                    |<---------+           |                   |
     |                    |                    |                      |                   |
     |  Select end date   |                    |                      |                   |
     |  (right calendar)  |                    |                      |                   |
     |----------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |                    |                    |  _validateDates()    |                   |
     |                    |                    |----------+           |                   |
     |                    |                    |          |           |                   |
     |                    |                    |<---------+           |                   |
     |                    |                    |                      |                   |
     |  Click "Confirmar" |                    |                      |                   |
     |----------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |                    |  DateTimeRange     |                      |                   |
     |                    |<-------------------|                      |                   |
     |                    |                    |                      |                   |
     |  Update dialog     |                    |                      |                   |
     |  with selected     |                    |                      |                   |
     |  dates             |                    |                      |                   |
     |<-------------------|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Click "Desa"      |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |                    |  setModulRA(modulId, ra.copyWith(         |                   |
     |                    |    startDate: range.start,                |                   |
     |                    |    endDate: range.end))                   |                   |
     |                    |-------------------------------------------->                  |
     |                    |                    |                      |                   |
     |                    |                    |                      |  Update RA dates  |
     |                    |                    |                      |------------------>|
     |                    |                    |                      |                   |
```

---

### 4.3 UC18 - View Calendar

```
+===========================================================================+
|              SEQUENCE DIAGRAM: UC18 - View Calendar                        |
+===========================================================================+

  Teacher            CalendarPage                          AppStateNotifier       AppState
     |                    |                                      |                   |
     |  Navigate to       |                                      |                   |
     |  /calendar         |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  ref.watch(appStateProvider)         |                   |
     |                    |------------------------------------->|                   |
     |                    |                                      |                   |
     |                    |  AppState (groups, moduls)           |                   |
     |                    |<-------------------------------------|                   |
     |                    |                                      |                   |
     |                    |  Build rasByDate map:                |                   |
     |                    |  for each group →                    |                   |
     |                    |    for each moduleId →               |                   |
     |                    |      for each RA with dates →        |                   |
     |                    |        add to map                    |                   |
     |                    |----------+                           |                   |
     |                    |          |                           |                   |
     |                    |<---------+                           |                   |
     |                    |                                      |                   |
     |  Display calendar  |                                      |                   |
     |  grid with colored |                                      |                   |
     |  dots on RA days   |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
     |  Click on day      |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  setState(() =>                      |                   |
     |                    |    _selectedDate = date)             |                   |
     |                    |----------+                           |                   |
     |                    |          |                           |                   |
     |                    |<---------+                           |                   |
     |                    |                                      |                   |
     |  Display right     |                                      |                   |
     |  panel with        |                                      |                   |
     |  sessions for day  |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
     |  Click "Anar a     |                                      |                   |
     |  notes diàries"    |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  context.go('/daily-notes')          |                   |
     |                    |------------------------------------------->              |
     |                    |                                      |                   |
```

---

### 4.4 UC16 (v2) - View Dashboard (Enhanced)

```
+===========================================================================+
|          SEQUENCE DIAGRAM: UC16 (v2) - View Dashboard (Enhanced)           |
+===========================================================================+

  Teacher           DashboardPage                          AppStateNotifier       AppState
     |                    |                                      |                   |
     |  Navigate to /     |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  ref.watch(appStateProvider)         |                   |
     |                    |------------------------------------->|                   |
     |                    |                                      |                   |
     |                    |  AppState (groups, moduls)           |                   |
     |                    |<-------------------------------------|                   |
     |                    |                                      |                   |
     |                    |  Compute activeRas:                  |                   |
     |                    |  for each group →                    |                   |
     |                    |    for each moduleId →               |                   |
     |                    |      for each RA →                   |                   |
     |                    |        if startDate <= today         |                   |
     |                    |           <= endDate                 |                   |
     |                    |        → add to activeRas            |                   |
     |                    |----------+                           |                   |
     |                    |          |                           |                   |
     |                    |<---------+                           |                   |
     |                    |                                      |                   |
     |  Display:          |                                      |                   |
     |  1. Welcome header |                                      |                   |
     |  2. Today's Classes|                                      |                   |
     |     (Wrap of       |                                      |                   |
     |     _TodayClassCard)|                                     |                   |
     |  3. Active RAs     |                                      |                   |
     |     (GridView of   |                                      |                   |
     |     _ActiveRaCard) |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
     |  Click on card     |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  context.go('/daily-notes')          |                   |
     |                    |------------------------------------------->              |
     |                    |                                      |                   |

+===========================================================================+
|                   _ActiveRaCard Details                                    |
+===========================================================================+

+---------------------------------------------------------+
|  [Color dot] GroupName          [ModulCode]             |
|  RA1 — Title of RA                                      |
|  [====Progress Bar=======------] 65%                    |
|  15/09 → 30/10                                          |
+---------------------------------------------------------+

- Left border color = Group.color
- Progress = elapsed days / total days
- Clicking navigates to daily notes
```

---

## 5. New Components

| Component | File | Purpose |
|-----------|------|---------|
| `DualDatePicker` | `lib/presentation/widgets/dual_date_picker.dart` | Side-by-side calendars for selecting date ranges |
| `_CalendarPanel` | (inside DualDatePicker) | Single calendar panel with month navigation |
| `CalendarPage` | `lib/presentation/pages/calendar_page.dart` | Full monthly calendar view with RA indicators |
| `_RaInfo` | (inside CalendarPage) | Data class holding Group+Modul+RA for display |
| `_TodayClassCard` | `lib/presentation/pages/dashboard_page.dart` | Card showing a group's session for today |
| `_ActiveRaCard` | `lib/presentation/pages/dashboard_page.dart` | Grid card showing RA with progress indicator |
| `_ActiveRaInfo` | (inside DashboardPage) | Data class with progress/daysRemaining computed |

### DualDatePicker API

```dart
/// Shows dialog and returns DateTimeRange or null if cancelled.
static Future<DateTimeRange?> show(
  BuildContext context, {
  DateTime? initialStart,
  DateTime? initialEnd,
  DateTime? firstDate,
  DateTime? lastDate,
});
```

### Preset Color Constants

```dart
const _presetColors = [
  '#4CAF50', // Green
  '#2196F3', // Blue
  '#FF9800', // Orange
  '#9C27B0', // Purple
  '#F44336', // Red
  '#00BCD4', // Cyan
  '#795548', // Brown
  '#607D8B', // Blue Grey
];
```

---

## 6. Navigation Changes

### Route Status Update

| Route | v1.0 Status | v2.0 Status |
|-------|-------------|-------------|
| `/calendar` | Placeholder | **Functional** (CalendarPage) |
| `/` | Basic welcome | **Enhanced** (Dashboard with active RAs) |

### Updated Navigation Map (Delta Only)

```
+===========================================================================+
|               NAVIGATION CHANGES (v2.0)                                    |
+===========================================================================+

Before (v1.0):                       After (v2.0):
+-------------+                      +-------------+
| /calendar   |                      | /calendar   |
| Placeholder |  ───────────────►    | CalendarPage|
| (Coming     |                      | (Full       |
|  soon)      |                      |  monthly    |
+-------------+                      |  calendar)  |
                                     +-------------+

+-------------+                      +-------------+
|     /       |                      |     /       |
| Dashboard   |  ───────────────►    | Dashboard   |
| (Welcome    |                      | (Today's    |
|  only)      |                      |  sessions + |
+-------------+                      |  Active RAs |
                                     |  grid)      |
                                     +-------------+

Note: Sidebar still shows "Calendari" link but it now routes to
      the functional CalendarPage instead of placeholder.
```

---

## Summary of Changes

| Category | Count | Items |
|----------|-------|-------|
| Domain Model Changes | 2 | Group.moduleIds, Group.color |
| New Use Cases | 3 | UC17, UC18, UC19 |
| Modified Use Cases | 3 | UC08, UC14, UC16 |
| New Components | 6 | DualDatePicker, CalendarPage, etc. |
| New Sequence Diagrams | 4 | See Section 4 |

---

**End of Delta Document**
