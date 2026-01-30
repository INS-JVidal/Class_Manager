# Class Activity Manager

## Project Requirements Document

**Version:** 1.0  
**Date:** January 2026  
**Project Type:** Cross-platform Desktop Application

---

## 1. Executive Summary

Class Activity Manager is a desktop application designed for educators in Catalan Vocational Training (Formació Professional) to plan, track, and document their teaching activities throughout the academic year. The application provides tools for session planning, content delivery tracking, homework management, and progress annotation—all organized by modules (mòduls), learning outcomes (Resultats d'Aprenentatge), groups, and calendar periods.

---

## 1.1 Context: Formació Professional a Catalunya

In the Catalan vocational training system, the teaching structure follows this hierarchy:

```
Cicle Formatiu (Training Cycle)
└── Mòdul Professional (Professional Module)
    └── Resultat d'Aprenentatge - RA (Learning Outcome)
        └── Criteris d'Avaluació - CA (Assessment Criteria)
```

**Key characteristics:**
- A teacher may teach multiple **mòduls** (modules) across different groups
- Each mòdul is divided into **RAs** (Resultats d'Aprenentatge)
- **RAs are strictly consecutive**: RA2 cannot start until RA1 is completed
- Each RA has a defined duration in hours
- The system must automatically calculate start/end dates based on the group's schedule

---

## 2. Project Objectives

1. Provide teachers with a centralized tool to plan class sessions in advance
2. Enable real-time annotation of what was actually covered during each session
3. Track homework assignments and their completion status
4. Generate reports and summaries of academic progress
5. Support multiple courses, groups, and academic years
6. Work offline with local data persistence

---

## 3. Technical Stack

### 3.1 Frontend
- **Framework:** Flutter (latest stable version)
- **Target Platforms:** Windows, macOS, Linux
- **State Management:** Riverpod or BLoC
- **UI Design:** Material Design 3 with custom theming

### 3.2 Backend / Data Layer
- **Database:** Document-based (options below)
  - **Primary Choice:** Isar (embedded, high-performance, Flutter-native)
  - **Alternative:** ObjectBox or Hive
- **Data Format:** JSON-serializable documents
- **Storage:** Local filesystem with optional cloud sync capability

### 3.3 Architecture
- **Pattern:** Clean Architecture with separation of concerns
  - Presentation Layer (UI/Widgets)
  - Application Layer (Use Cases/Controllers)
  - Domain Layer (Entities/Business Logic)
  - Data Layer (Repositories/Data Sources)

---

## 4. Functional Requirements

### 4.1 Academic Structure Management

#### FR-4.1.1 Academic Years
- Create, edit, and archive academic years
- Define start and end dates
- Set term/semester divisions
- Mark holidays and non-teaching periods

#### FR-4.1.2 Mòduls (Professional Modules)
- Create modules with name, code (e.g., "MP06"), and description
- Assign modules to academic years
- Define total hours allocation
- Set global learning objectives
- Link to official curriculum reference (optional)

#### FR-4.1.3 Resultats d'Aprenentatge (RAs)
- Add RAs to a module after creation
- Define RA number (RA1, RA2, etc.), title, and description
- Set duration in hours for each RA
- **Automatic date calculation:**
  - System calculates start date based on previous RA end date (or module start for RA1)
  - System calculates end date based on duration and group schedule
  - Dates update automatically when durations change or RAs are reordered
- Define Criteris d'Avaluació (CA) for each RA
- RAs are strictly sequential—no overlap allowed
- Visual timeline showing RA distribution across the academic year

#### FR-4.1.4 Groups/Classes
- Create student groups (e.g., "DAW1-A", "SMX2-B")
- Assign groups to modules (a group takes a specific module)
- Define group schedules (day, time, room, hours per week)
- **Schedule determines RA date calculations**
- Track group-specific notes
- Support for multiple groups taking the same module with different schedules

### 4.2 RA Date Calculation (Use Case)

#### UC-4.2.1 Automatic RA Scheduling

**Preconditions:**
- Module exists with total hours defined
- Group exists with weekly schedule defined
- Academic year has holidays/non-teaching days marked

**Flow:**
1. Teacher creates a new module (e.g., "MP06 - Desenvolupament Web en Entorn Client")
2. Teacher adds RAs sequentially:
   - RA1: "Selecciona les arquitectures i tecnologies..." - 25 hours
   - RA2: "Escriu sentències simples..." - 30 hours
   - RA3: "Escriu codi amb funcions..." - 35 hours
   - (etc.)
3. System automatically calculates for each RA:
   - **Start Date**: Day after previous RA ends (or module start date for RA1)
   - **End Date**: Based on hours ÷ weekly hours, skipping holidays
   - **Number of Sessions**: Based on group's session duration

**Example Calculation:**
```
Group: DAW1-A
Schedule: Monday 15:00-18:00 (3h), Wednesday 15:00-18:00 (3h)
Weekly hours: 6h
Module start: 2025-09-15

RA1 (25 hours):
  - Start: 2025-09-15 (Monday)
  - Sessions needed: ⌈25 / 3⌉ = 9 sessions
  - End: 2025-10-08 (Wednesday) 
  - Actual hours: 27h (rounded to complete sessions)

RA2 (30 hours):
  - Start: 2025-10-13 (Monday, next session after RA1)
  - Sessions needed: ⌈30 / 3⌉ = 10 sessions
  - End: 2025-11-05 (Wednesday)
```

**Postconditions:**
- All RAs have calculated start/end dates
- Sessions can be pre-generated for planning
- Timeline visualization is updated

#### UC-4.2.2 RA Duration Adjustment

**Flow:**
1. Teacher modifies RA2 duration from 30h to 40h
2. System recalculates RA2 end date
3. System cascades changes: RA3, RA4, etc. start/end dates update
4. Warning shown if total exceeds academic year or available time

#### UC-4.2.3 RA Hours Validation

**Business Rule:** The sum of all RA durations should equal the module's total hours.

**Flow:**
1. Teacher adds/modifies RA durations
2. System continuously calculates: `sumRAHours = Σ(ra.durationHours)`
3. System compares with `module.totalHours`
4. UI displays validation status:
   - ✓ Green: `sumRAHours == module.totalHours`
   - ⚠ Yellow: `sumRAHours < module.totalHours` (hours remaining)
   - ⚠ Red: `sumRAHours > module.totalHours` (excess hours)
5. Warning message shows difference (e.g., "Falten 15 hores per assignar" or "Sobren 10 hores")

**Note:** This is a soft validation—teachers can proceed with mismatched hours but receive visual warnings.

### 4.3 Session Planning

#### FR-4.3.1 Session Templates
- Create reusable session templates
- Define estimated duration
- Include materials and resources list
- Tag with RAs and Criteris d'Avaluació

#### FR-4.3.2 Session Planning
- Plan sessions on a calendar view
- **Each session is linked to a specific RA**
- Assign planned content (topics, activities)
- Set learning objectives aligned with RA criteria
- Attach resources (links, file references)
- Copy/duplicate sessions across groups
- Auto-generate session slots based on calculated RA dates

#### FR-4.3.3 RA Content Management
- Define detailed content within each RA
- Break down into topics and learning activities
- Map Criteris d'Avaluació (CA) to specific sessions
- Track coverage percentage per RA
- Visual progress indicator per RA

### 4.4 Session Tracking

#### FR-4.4.1 Session Annotation
- Mark session as completed
- Record what was actually covered
- **Track which CAs were addressed**
- Note deviations from plan
- Add observations and incidents
- Record attendance notes (general, not per-student)

#### FR-4.4.2 Progress Tracking
- Visual progress indicator per module/group
- **RA-level progress tracking**
- Compare planned vs. actual coverage
- Identify delayed or advanced RAs
- Generate catch-up suggestions
- Alert when RA is falling behind schedule

### 4.4 Homework Management

#### FR-4.4.1 Assignment Creation
- Create homework with title and description
- Set due date and estimated effort
- Link to session/topic
- Define submission format

#### FR-4.4.2 Assignment Tracking
- Mark assignments as reviewed
- Add completion notes
- Track patterns across groups
- Archive completed assignments

### 4.5 Reporting

#### FR-4.5.1 Progress Reports
- Course coverage summary
- Planned vs. actual comparison
- Time distribution by topic
- Homework completion rates

#### FR-4.5.2 Export Capabilities
- Export to PDF (reports, session logs)
- Export to CSV (data tables)
- Export to Markdown (documentation)
- Print-friendly views

### 4.6 Search and Filter

#### FR-4.6.1 Global Search
- Search across all content
- Filter by date range
- Filter by course/group
- Filter by tags/topics

#### FR-4.6.2 Quick Access
- Recent sessions
- Upcoming sessions
- Pending homework
- Bookmarked items

---

## 5. Non-Functional Requirements

### 5.1 Performance
- Application launch: < 3 seconds
- Search results: < 500ms
- Data sync: Background, non-blocking
- Support for 5+ years of historical data

### 5.2 Usability
- Intuitive navigation with minimal training
- Keyboard shortcuts for common actions
- Responsive layout (minimum 1024x768)
- Accessibility compliance (WCAG 2.1 AA)

### 5.3 Reliability
- Automatic data backup
- Crash recovery with data integrity
- Offline-first operation
- Data validation and error handling

### 5.4 Security
- Local data encryption (optional)
- No sensitive student data stored
- Secure backup file format

### 5.5 Maintainability
- Comprehensive logging
- Modular codebase
- Unit test coverage > 70%
- Documentation for all public APIs

---

## 6. Data Model

### 6.1 Core Entities

```
┌─────────────────────────────────────────────────────────────────┐
│              DOCUMENT SCHEMA - Formació Professional            │
└─────────────────────────────────────────────────────────────────┘

AcademicYear
├── id: String (UUID)
├── name: String (e.g., "2025-2026")
├── startDate: DateTime
├── endDate: DateTime
├── terms: List<Term>
├── holidays: List<Holiday>
├── isActive: Boolean
└── createdAt: DateTime

Term
├── id: String (UUID)
├── name: String (e.g., "1r Trimestre")
├── startDate: DateTime
└── endDate: DateTime

Holiday
├── id: String (UUID)
├── name: String (e.g., "Nadal", "Setmana Santa")
├── startDate: DateTime
├── endDate: DateTime
└── isRecurring: Boolean

Modul (Professional Module)
├── id: String (UUID)
├── academicYearId: String (FK)
├── code: String (e.g., "MP06")
├── name: String (e.g., "Desenvolupament Web en Entorn Client")
├── description: String
├── totalHours: Integer
├── objectives: List<String>
├── officialReference: String (optional, link to curriculum)
└── createdAt: DateTime

ResultatAprenentatge (RA - Learning Outcome)
├── id: String (UUID)
├── modulId: String (FK)
├── number: Integer (1, 2, 3...)
├── code: String (e.g., "RA1", "RA2")
├── title: String
├── description: String
├── durationHours: Integer
├── order: Integer (for sequencing)
├── criterisAvaluacio: List<CriteriAvaluacio>
└── createdAt: DateTime

CriteriAvaluacio (CA - Assessment Criterion)
├── id: String (UUID)
├── code: String (e.g., "CA1.1", "CA1.2")
├── description: String
└── order: Integer

Group
├── id: String (UUID)
├── modulId: String (FK)
├── name: String (e.g., "DAW1-A")
├── schedule: List<ScheduleSlot>
├── modulStartDate: DateTime (when this group starts the module)
├── notes: String
└── createdAt: DateTime

ScheduleSlot
├── dayOfWeek: Integer (1=Monday, 7=Sunday)
├── startTime: Time
├── endTime: Time
├── room: String
└── durationMinutes: Integer

RASchedule (Calculated - per Group)
├── id: String (UUID)
├── groupId: String (FK)
├── raId: String (FK)
├── calculatedStartDate: DateTime
├── calculatedEndDate: DateTime
├── sessionsCount: Integer
├── actualHours: Integer (may differ due to rounding)
├── status: Enum [pending, in_progress, completed]
└── lastCalculatedAt: DateTime

Session
├── id: String (UUID)
├── groupId: String (FK)
├── raScheduleId: String (FK)
├── date: DateTime
├── startTime: Time
├── endTime: Time
├── plannedContent: PlannedContent
├── actualContent: ActualContent (nullable)
├── status: Enum [planned, completed, cancelled]
├── homework: List<HomeworkRef>
└── createdAt: DateTime

PlannedContent
├── topics: List<String>
├── criterisToAddress: List<String> (CA codes)
├── objectives: List<String>
├── materials: List<Resource>
├── activities: List<String>
└── notes: String

ActualContent
├── topicsCovered: List<String>
├── criterisAddressed: List<String> (CA codes)
├── observations: String
├── incidents: String
├── attendanceNotes: String
├── completedAt: DateTime
└── deviationNotes: String

Resource
├── id: String (UUID)
├── type: Enum [link, file, document, video]
├── title: String
├── url: String
└── description: String

Homework
├── id: String (UUID)
├── sessionId: String (FK)
├── raId: String (FK, optional)
├── title: String
├── description: String
├── dueDate: DateTime
├── estimatedEffort: Integer (minutes)
├── relatedCriteris: List<String> (CA codes)
├── status: Enum [assigned, reviewed, archived]
├── reviewNotes: String
└── createdAt: DateTime
```

### 6.2 RA Date Calculation Algorithm

```
┌─────────────────────────────────────────────────────────────────┐
│                  RA DATE CALCULATION LOGIC                       │
└─────────────────────────────────────────────────────────────────┘

FUNCTION calculateRASchedule(group, modul):
    currentDate = group.modulStartDate
    
    FOR EACH ra IN modul.ras ORDER BY ra.order:
        
        # Find first valid session date
        startDate = findNextSessionDate(currentDate, group.schedule, holidays)
        
        # Calculate sessions needed
        sessionDuration = getSessionDuration(group.schedule)
        sessionsNeeded = CEILING(ra.durationHours / (sessionDuration / 60))
        
        # Calculate end date by iterating through sessions
        endDate = startDate
        sessionsScheduled = 0
        
        WHILE sessionsScheduled < sessionsNeeded:
            IF isValidSessionDate(endDate, group.schedule, holidays):
                sessionsScheduled++
                IF sessionsScheduled < sessionsNeeded:
                    endDate = nextDay(endDate)
            ELSE:
                endDate = nextDay(endDate)
        
        # Create RASchedule record
        CREATE RASchedule(
            groupId: group.id,
            raId: ra.id,
            calculatedStartDate: startDate,
            calculatedEndDate: endDate,
            sessionsCount: sessionsNeeded,
            actualHours: sessionsNeeded * (sessionDuration / 60)
        )
        
        # Set next RA start after this one ends
        currentDate = nextDay(endDate)
    
    RETURN allRASchedules

FUNCTION recalculateFromRA(group, modifiedRA):
    # Recalculate only from the modified RA onwards
    FOR EACH ra IN modul.ras WHERE ra.order >= modifiedRA.order:
        recalculate(ra)
```

### 6.3 Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐
│ AcademicYear │       │    Modul     │
│──────────────│       │──────────────│
│ id           │◄──────│ academicYearId│
│ name         │   1:N │ code         │
│ startDate    │       │ name         │
│ endDate      │       │ totalHours   │
└──────────────┘       └──────┬───────┘
                              │
                              │ 1:N
                              ▼
                       ┌──────────────┐
                       │      RA      │
                       │──────────────│
                       │ modulId      │
                       │ number       │
                       │ durationHours│
                       │ order        │
                       └──────┬───────┘
                              │
            ┌─────────────────┴─────────────────┐
            │ 1:N                               │
            ▼                                   │
     ┌──────────────┐                          │
     │   Criteri    │                          │
     │  Avaluació   │                          │
     │──────────────│                          │
     │ raId         │                          │
     │ code         │                          │
     │ description  │                          │
     └──────────────┘                          │
                                               │
┌──────────────┐       ┌──────────────┐        │
│    Group     │       │  RASchedule  │        │
│──────────────│       │  (Calculated)│        │
│ modulId      │◄──────│ groupId      │        │
│ name         │   1:N │ raId         │◄───────┘
│ schedule     │       │ startDate    │
│ modulStart   │       │ endDate      │
└──────┬───────┘       │ sessionsCount│
       │               └──────┬───────┘
       │                      │
       │ 1:N                  │ 1:N
       ▼                      ▼
┌──────────────────────────────────┐
│            Session               │
│──────────────────────────────────│
│ groupId                          │
│ raScheduleId                     │
│ date                             │
│ plannedContent                   │
│ actualContent                    │
└──────────────────────────────────┘
```

### 6.4 Document Collections

| Collection     | Description                           | Indexes                              |
|----------------|---------------------------------------|--------------------------------------|
| academic_years | Academic year documents               | isActive, startDate                  |
| moduls         | Professional modules                  | academicYearId, code                 |
| ras            | Resultats d'Aprenentatge              | modulId, order, number               |
| groups         | Class groups                          | modulId, name                        |
| ra_schedules   | Calculated RA dates per group         | groupId, raId, calculatedStartDate   |
| sessions       | Individual class sessions             | groupId, raScheduleId, date, status  |
| homework       | Homework assignments                  | sessionId, raId, dueDate, status     |
| templates      | Reusable session templates            | tags, name                           |
| settings       | User preferences and config           | key                                  |

---

## 7. User Interface Design

### 7.1 Main Navigation Structure

```
┌────────────────────────────────────────────────────────────┐
│  [Logo]  Class Activity Manager          [Search] [Settings]│
├────────────┬───────────────────────────────────────────────┤
│            │                                               │
│  Dashboard │         [Content Area]                        │
│            │                                               │
│  Calendar  │   Displays selected view based on            │
│            │   navigation selection                        │
│  Mòduls    │                                               │
│            │                                               │
│  Grups     │                                               │
│            │                                               │
│  Tasques   │                                               │
│            │                                               │
│  Informes  │                                               │
│            │                                               │
│  ────────  │                                               │
│  Arxiu     │                                               │
│            │                                               │
└────────────┴───────────────────────────────────────────────┘
```

### 7.2 Key Views

#### Dashboard
- Today's sessions overview
- Upcoming sessions (next 7 days)
- Pending homework review
- **RA progress indicators per module**
- Quick stats (coverage %, sessions this week)
- Recent activity feed

#### Calendar View
- Month/Week/Day views
- **Color-coded by module and RA**
- Drag-and-drop session scheduling
- Quick session preview on hover
- **RA boundaries shown as visual markers**

#### Session Detail View
- Split view: Plan (left) | Actual (right)
- **Current RA indicator and progress**
- Rich text editor for notes
- Checkbox list for topics and CAs addressed
- Attached resources list
- Linked homework section

#### Module Management (Gestió de Mòduls)
- Module list with RA progress indicators
- **RA timeline view with calculated dates**
- **RA editor with duration and automatic date recalculation**
- Bulk session generation from RA schedule
- Coverage heat map per RA
- Criteris d'Avaluació checklist

#### RA Detail View
- RA information and objectives
- **Visual timeline within module**
- List of associated sessions
- CA completion tracking
- Content planning area

### 7.3 RA Management Interface

```
┌─────────────────────────────────────────────────────────────────┐
│  MP06 - Desenvolupament Web en Entorn Client     [Edit] [Delete]│
├─────────────────────────────────────────────────────────────────┤
│  Total: 132h | Grup: DAW1-A | Inici: 15/09/2025                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─── RA Timeline ──────────────────────────────────────────┐  │
│  │                                                           │  │
│  │  RA1 ████████░░  RA2 ░░░░░░░░░░  RA3 ░░░░░░░░░░  RA4 ... │  │
│  │  25h (27h)       30h             35h             42h      │  │
│  │  15/09-08/10     13/10-05/11     10/11-17/12     ...      │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌─── RAs ──────────────────────────────────────────────────┐  │
│  │                                                           │  │
│  │  ☑ RA1: Selecciona arquitectures i tecnologies...        │  │
│  │     Durada: [25h]  Inici: 15/09/2025  Fi: 08/10/2025     │  │
│  │     Sessions: 9 | Progrés: ████████░░ 80%                 │  │
│  │     [Expandir CAs] [Editar] [▲] [▼]                       │  │
│  │                                                           │  │
│  │  ○ RA2: Escriu sentències simples...                     │  │
│  │     Durada: [30h]  Inici: 13/10/2025  Fi: 05/11/2025     │  │
│  │     Sessions: 10 | Progrés: ░░░░░░░░░░ 0%                │  │
│  │     [Expandir CAs] [Editar] [▲] [▼]                       │  │
│  │                                                           │  │
│  │  [+ Afegir RA]                                            │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ⚠ Avís: Total RAs (132h) coincideix amb hores del mòdul ✓    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 7.4 Interaction Patterns

| Action              | Trigger                    | Result                       |
|---------------------|----------------------------|------------------------------|
| Quick Add Session   | Keyboard: Ctrl+N           | Modal with minimal fields    |
| Mark Complete       | Button or Keyboard: Ctrl+D | Opens annotation panel       |
| Search              | Keyboard: Ctrl+K           | Global search overlay        |
| Navigate Back       | Keyboard: Esc or Backspace | Return to previous view      |
| Save                | Automatic + Ctrl+S         | Saves current document       |

---

## 8. Project Structure

```
class_activity_manager/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── extensions/
│   │   ├── theme/
│   │   └── utils/
│   │       └── date_calculator.dart    # RA date calculation utilities
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   └── local/
│   │   │       ├── academic_year_local_ds.dart
│   │   │       ├── modul_local_ds.dart
│   │   │       ├── ra_local_ds.dart
│   │   │       ├── group_local_ds.dart
│   │   │       └── session_local_ds.dart
│   │   ├── models/
│   │   │   ├── academic_year_model.dart
│   │   │   ├── modul_model.dart
│   │   │   ├── ra_model.dart
│   │   │   ├── ca_model.dart           # Criteris d'Avaluació
│   │   │   ├── group_model.dart
│   │   │   ├── schedule_slot_model.dart
│   │   │   ├── ra_schedule_model.dart
│   │   │   └── session_model.dart
│   │   └── repositories/
│   │
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   │       ├── modul/
│   │       ├── ra/
│   │       │   ├── add_ra_usecase.dart
│   │       │   ├── update_ra_duration_usecase.dart
│   │       │   ├── reorder_ra_usecase.dart
│   │       │   └── calculate_ra_dates_usecase.dart
│   │       ├── session/
│   │       └── homework/
│   │
│   ├── presentation/
│   │   ├── providers/          # or blocs/
│   │   ├── pages/
│   │   │   ├── dashboard/
│   │   │   ├── calendar/
│   │   │   ├── moduls/         # Module management
│   │   │   │   ├── modul_list_page.dart
│   │   │   │   ├── modul_detail_page.dart
│   │   │   │   └── ra_editor_page.dart
│   │   │   ├── groups/
│   │   │   ├── sessions/
│   │   │   ├── homework/
│   │   │   ├── reports/
│   │   │   └── settings/
│   │   └── widgets/
│   │       ├── common/
│   │       └── specific/
│   │           ├── ra_timeline_widget.dart
│   │           ├── ra_card_widget.dart
│   │           └── ca_checklist_widget.dart
│   │
│   └── services/
│       ├── database_service.dart
│       ├── ra_schedule_service.dart    # RA date calculation service
│       ├── export_service.dart
│       └── backup_service.dart
│
├── test/
│   ├── unit/
│   │   └── ra_date_calculation_test.dart
│   ├── widget/
│   └── integration/
│
├── assets/
│   ├── icons/
│   ├── images/
│   └── fonts/
│
├── pubspec.yaml
└── README.md
```

---

## 9. Development Phases

### Phase 1: Foundation (Weeks 1-3)
- [ ] Project setup and architecture
- [ ] Database schema implementation
- [ ] Core entity models
- [ ] Basic CRUD operations
- [ ] Navigation shell

### Phase 2: Core Features (Weeks 4-7)
- [ ] Academic year management
- [ ] Course and group management
- [ ] Session planning interface
- [ ] Calendar view implementation
- [ ] Session annotation system

### Phase 3: Extended Features (Weeks 8-10)
- [ ] Homework management
- [ ] Curriculum tracking
- [ ] Search and filtering
- [ ] Dashboard implementation

### Phase 4: Polish (Weeks 11-12)
- [ ] Reporting and exports
- [ ] Settings and preferences
- [ ] Data backup/restore
- [ ] Testing and bug fixes
- [ ] Documentation

---

## 10. Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  # OR flutter_bloc: ^8.1.0
  
  # Database
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  
  # Routing
  go_router: ^13.0.0
  
  # UI Components
  flutter_adaptive_scaffold: ^0.1.0
  table_calendar: ^3.0.9
  syncfusion_flutter_calendar: ^24.0.0  # Alternative
  
  # Utilities
  uuid: ^4.2.0
  intl: ^0.18.0
  path_provider: ^2.1.0
  file_picker: ^6.1.0
  
  # Export
  pdf: ^3.10.0
  printing: ^5.11.0
  csv: ^5.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  isar_generator: ^3.1.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0
  flutter_lints: ^3.0.0
```

---

## 11. Testing Strategy

### 11.1 Unit Tests
- All use cases
- Repository implementations
- Data transformations
- Utility functions
- **RA date calculation algorithm**

### 11.2 Widget Tests
- Individual widget behavior
- Form validation
- Navigation flows
- State management
- **RA editor component**

### 11.3 Integration Tests
- Database operations
- Export functionality
- End-to-end workflows
- **RA creation and date cascade updates**

### 11.4 Critical Test Cases for RA Calculation

| Test Case | Input | Expected Output |
|-----------|-------|-----------------|
| TC-01: Basic RA scheduling | Module with 2 RAs (25h, 30h), Group with 6h/week, start 15/09 | RA1: 15/09-08/10, RA2: 13/10-10/11 |
| TC-02: Holiday handling | RA spanning Christmas break (23/12-07/01) | Dates skip holiday period |
| TC-03: Duration change cascade | Change RA2 from 30h to 40h | RA3, RA4, etc. dates recalculated |
| TC-04: RA reorder | Move RA3 before RA2 | All dates recalculated from RA2 position |
| TC-05: Overflow warning | Total RA hours exceed remaining year | Warning displayed, dates shown in red |
| TC-06: Multiple groups same module | 2 groups with different schedules | Each group has independent RA dates |

### 11.5 Test Coverage Goals
| Layer        | Target Coverage |
|--------------|-----------------|
| Domain       | 90%             |
| Data         | 80%             |
| Presentation | 70%             |
| Overall      | 75%             |

---

## 12. Future Enhancements (v2.0+)

1. **Cloud Sync** - Optional synchronization across devices
2. **Student Roster** - Basic student list per group (no grades)
3. **Collaboration** - Share courses with other teachers
4. **Templates Marketplace** - Community session templates
5. **Analytics Dashboard** - Teaching pattern insights
6. **Mobile Companion** - Read-only mobile app for quick reference
7. **AI Suggestions** - Smart scheduling and pacing recommendations
8. **Integration APIs** - Connect with LMS platforms

---

## 13. Glossary

| Term (Català)               | Term (English)         | Definition                                                                 |
|-----------------------------|------------------------|----------------------------------------------------------------------------|
| Curs Acadèmic               | Academic Year          | The full teaching period, typically September to June                      |
| Cicle Formatiu              | Training Cycle         | A complete vocational training program (e.g., DAW, SMX)                    |
| Mòdul Professional (MP)     | Professional Module    | A subject within a training cycle (e.g., "MP06 - Desenvolupament Web")     |
| Resultat d'Aprenentatge (RA)| Learning Outcome       | A measurable learning objective within a module; RAs are consecutive       |
| Criteri d'Avaluació (CA)    | Assessment Criterion   | Specific criteria used to evaluate achievement of an RA                    |
| Grup                        | Group                  | A specific class of students taking a module (e.g., "DAW1-A")              |
| Sessió                      | Session                | A single class meeting                                                     |
| Horari                      | Schedule               | The weekly timetable defining when sessions occur                          |
| Contingut Planificat        | Planned Content        | What the teacher intends to cover in a session                             |
| Contingut Real              | Actual Content         | What was actually covered, recorded after the session                      |
| Tasca                       | Homework/Assignment    | Work assigned to students outside of class                                 |
| RASchedule                  | RA Schedule            | System-calculated start/end dates for an RA based on group schedule        |

---

## 14. Acceptance Criteria

The project will be considered complete when:

1. ✓ All functional requirements from Section 4 are implemented
2. ✓ Application runs on Windows, macOS, and Linux
3. ✓ Test coverage meets targets from Section 11.4
4. ✓ Performance benchmarks from Section 5.1 are met
5. ✓ Documentation is complete (README, API docs, user guide)
6. ✓ No critical or high-severity bugs remain open

---

*Document prepared for educational and development purposes.*