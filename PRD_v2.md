# Class Activity Manager

## Project Requirements Document

**Version:** 1.1  
**Date:** January 2026  
**Project Type:** Cross-platform Desktop & Web Application  
**Target Users:** Vocational Training Teachers (Formació Professional, Catalunya)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
   - 1.1 [Context: Formació Professional a Catalunya](#11-context-formació-professional-a-catalunya)
2. [Project Objectives](#2-project-objectives)
3. [Technical Stack](#3-technical-stack)
4. [Functional Requirements](#4-functional-requirements)
   - 4.1 Academic Structure Management
   - 4.2 RA Date Calculation
   - 4.3 Session Planning
   - 4.4 Session Tracking
   - 4.5 Homework Management
   - 4.6 Reporting
   - 4.7 Search and Filter
   - 4.8 Dashboard
   - 4.9 Settings and Preferences
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Data Model](#6-data-model)
7. [User Interface Design](#7-user-interface-design)
8. [Project Structure](#8-project-structure)
9. [Development Phases](#9-development-phases)
10. [Dependencies](#10-dependencies)
11. [Testing Strategy](#11-testing-strategy)
12. [Future Enhancements](#12-future-enhancements-v20)
13. [Glossari](#13-glossari)
14. [Acceptance Criteria](#14-acceptance-criteria)
- [Appendix A: MongoDB Atlas Setup Guide](#appendix-a-mongodb-atlas-setup-guide)

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
5. Support multiple modules, groups, and academic years
6. **Sync data across devices** — work from desktop or web browser seamlessly

---

## 3. Technical Stack

### 3.1 Frontend
- **Framework:** Flutter (latest stable version)
- **Target Platforms:** Windows, macOS, Linux, **Web**
- **State Management:** Riverpod or BLoC
- **UI Design:** Material Design 3 with custom theming

### 3.2 Backend / Data Layer
- **Database:** MongoDB Atlas (cloud-hosted)
- **API:** MongoDB Atlas Data API (built-in REST API, no custom backend needed)
- **Data Format:** JSON/BSON documents
- **Sync:** Automatic via cloud — all platforms access same database

### 3.3 Why No Custom Backend?

For the development phase (single user), MongoDB Atlas Data API provides:
- Direct HTTPS calls from Flutter to MongoDB
- No server to deploy or maintain
- Free tier (512MB) sufficient for single teacher
- Easy migration to full backend later if needed

```
┌─────────────────┐     ┌─────────────────┐
│ Flutter Desktop │     │  Flutter Web    │
└────────┬────────┘     └────────┬────────┘
         │       HTTPS           │
         └───────────┬───────────┘
                     ▼
          ┌─────────────────────┐
          │  MongoDB Atlas      │
          │  Data API (REST)    │
          │  ──────────────     │
          │  No backend code    │
          │  Free tier: 512MB   │
          └─────────────────────┘
```

### 3.4 Architecture
- **Pattern:** Clean Architecture with separation of concerns
  - Presentation Layer (UI/Widgets)
  - Application Layer (Use Cases/Controllers)
  - Domain Layer (Entities/Business Logic)
  - Data Layer (Repositories/Data Sources)

### 3.5 Future Scalability Path

When multi-user or advanced features are needed:

| Phase | Architecture | Trigger |
|-------|--------------|---------|
| **Current** | Flutter → Atlas Data API | Development/single user |
| **Phase 2** | Flutter → Dart Frog API → MongoDB | Multi-user auth needed |
| **Phase 3** | + Real-time sync | Collaboration features |

The Repository pattern allows swapping data sources without changing business logic.

---

## 4. Functional Requirements

### 4.1 Academic Structure Management

#### FR-4.1.1 Academic Years
- Create, edit, and archive academic years
- Define start and end dates
- **Define vacation periods** (Nadal, Setmana Santa, etc.) specific to this academic year
- Vacation periods are date ranges where no classes occur

#### FR-4.1.2 Recurring Holidays (Festius Recurrents)
- **Configure once, apply every year**
- Define holidays by month and day (e.g., 25/12 = Nadal, 01/01 = Cap d'Any)
- Enable/disable individual holidays without deleting them
- Pre-configured defaults for Catalunya:
  - 01/01 - Cap d'Any
  - 06/01 - Reis
  - 01/05 - Dia del Treball
  - 24/06 - Sant Joan
  - 15/08 - L'Assumpció
  - 11/09 - Diada Nacional de Catalunya
  - 12/10 - Festa Nacional d'Espanya
  - 01/11 - Tots Sants
  - 06/12 - Dia de la Constitució
  - 08/12 - La Immaculada
  - 25/12 - Nadal
  - 26/12 - Sant Esteve

#### FR-4.1.3 Mòduls (Professional Modules)
- Create modules with name, code (e.g., "MP06"), and description
- Assign modules to academic years
- Define total hours allocation
- Set global learning objectives
- Link to official curriculum reference (optional)

#### FR-4.1.4 Resultats d'Aprenentatge (RAs)
- Add RAs to a module after creation
- Define RA number (RA1, RA2, etc.), title, and description
- Set duration in hours for each RA
- **Automatic date calculation:**
  - System calculates start date based on previous RA end date (or GrupModul start for RA1)
  - System calculates end date based on duration and GrupModul schedule
  - **Calculation skips recurring holidays and vacation periods**
  - Shows lost hours/sessions due to holidays
  - Dates update automatically when durations change or RAs are reordered
- **Manual date override:**
  - Teacher can manually adjust start/end dates
  - System shows both calculated and manual dates when different
  - Manual dates take precedence over calculated ones
  - Warning shown if manual dates cause RA overlap
- Define Criteris d'Avaluació (CA) for each RA
- RAs are strictly sequential—no overlap allowed
- Visual timeline showing RA distribution across the academic year

#### FR-4.1.5 Grups (Classes d'alumnes)
- Create student groups (e.g., "DAW1-A", "SMX2-B")
- Assign groups to an academic year
- Track group-specific notes
- A group can take multiple modules (via GrupModul)

#### FR-4.1.6 GrupModul (Assignacions Grup-Mòdul)
- **Assign a module to a group** with specific schedule and start date
- Define weekly schedule for each assignment (day, time, room)
- Set the start date for when this group begins this module
- **Schedule determines RA date calculations**
- Support for:
  - Same group taking multiple modules (different schedules)
  - Same module assigned to multiple groups (different schedules)
- View all modules assigned to a group
- View all groups assigned to a module

### 4.2 RA Date Calculation (Use Case)

#### UC-4.2.1 Automatic RA Scheduling

**Preconditions:**
- Module exists with RAs defined (total hours)
- Group exists in the academic year
- **GrupModul assignment created** with schedule and start date
- Recurring holidays are configured
- Academic year vacation periods are defined

**Flow:**
1. Teacher creates a group (e.g., "DAW1-A") for the academic year
2. Teacher creates a module (e.g., "MP06") with its RAs
3. **Teacher creates a GrupModul assignment:**
   - Selects group: DAW1-A
   - Selects module: MP06
   - Sets start date: 2025-09-15
   - Defines schedule: Monday 15:00-18:00, Wednesday 15:00-18:00
4. System automatically calculates RASchedule for each RA:
   - **Skips recurring holidays** (e.g., 12/10, 01/11, 06/12, 08/12)
   - **Skips vacation periods** (e.g., Nadal 23/12-07/01)
   - Calculates lost hours/sessions due to holidays
   - **Start Date**: Day after previous RA ends (or GrupModul start date for RA1)
   - **End Date**: Based on hours ÷ session hours, skipping non-teaching days

**Example Calculation with Holidays:**
```
GrupModul: DAW1-A + MP06
Schedule: Monday 15:00-18:00 (3h), Wednesday 15:00-18:00 (3h)
Weekly hours: 6h
Start date: 2025-11-03

Recurring holidays in period: 01/11 (Tots Sants), 06/12, 08/12
Vacation: Nadal 23/12-07/01

RA2 (30 hours):
  - Start: 2025-11-03 (Monday)
  - Sessions needed: ⌈30 / 3⌉ = 10 sessions
  - Sessions lost to holidays: 2 (06/12 is a Saturday so no impact, but if schedule had Friday...)
  - Skips: Nadal vacation period
  - End: 2025-12-17 (Wednesday, before Nadal)
  
  If RA continues after Nadal:
  - Resumes: 2025-01-08 (Wednesday)
  - End: 2025-01-13 (Monday)
  
  - Actual sessions: 10
  - Actual hours: 30h
  - Holiday sessions lost: 2
  - Holiday hours lost: 6h
```

**Postconditions:**
- All RAs have calculated start/end dates
- Lost hours due to holidays are tracked
- Sessions can be pre-generated for planning
- Timeline visualization is updated

#### UC-4.2.2 Manual Date Override

**Preconditions:**
- RASchedule exists with calculated dates

**Flow:**
1. Teacher views the RA timeline for a GrupModul
2. Teacher sees calculated dates don't fit their needs (e.g., exam period, special events)
3. Teacher clicks "Edit dates manually" on the RA
4. System shows:
   - Current calculated dates (read-only)
   - Editable fields for manual start/end dates
5. Teacher enters new dates
6. System validates:
   - Manual dates don't overlap with adjacent RAs
   - Warning if dates extend beyond academic year
7. System saves with `isManuallyOverridden = true`
8. UI shows indicator that dates are manually set (e.g., 🔧 icon)

**Recalculation Behavior:**
- When module RAs change, system asks: "Recalculate all dates? (Manual overrides will be preserved)"
- Option to recalculate only non-overridden RAs
- Option to reset all to calculated dates

#### UC-4.2.3 RA Duration Adjustment

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

### 4.5 Homework Management

#### FR-4.5.1 Assignment Creation
- Create homework with title and description
- Set due date and estimated effort
- Link to session/RA
- Define submission format

#### FR-4.5.2 Assignment Tracking
- Mark assignments as reviewed
- Add completion notes
- Track patterns across groups
- Archive completed assignments

### 4.6 Reporting

#### FR-4.6.1 Progress Reports
- Module coverage summary
- Planned vs. actual comparison
- Time distribution by RA
- Homework completion rates

#### FR-4.6.2 Export Capabilities
- Export to PDF (reports, session logs)
- Export to CSV (data tables)
- Export to Markdown (documentation)
- Print-friendly views

### 4.7 Search and Filter

#### FR-4.7.1 Global Search
- Search across all content
- Filter by date range
- Filter by module/group
- Filter by RA/tags

#### FR-4.7.2 Quick Access
- Recent sessions
- Upcoming sessions
- Pending homework
- Bookmarked items

### 4.8 Dashboard

#### FR-4.8.1 Overview Panel
- Today's sessions with quick access
- Upcoming sessions (next 7 days)
- Current RA progress per module/group
- Pending homework requiring review

#### FR-4.8.2 Alerts and Notifications
- RA behind schedule warnings
- Upcoming deadlines
- Uncompleted session annotations
- Hours mismatch warnings (RA vs module total)

### 4.9 Settings and Preferences

#### FR-4.9.1 Application Settings
- Date/time format
- Default session duration
- Theme (light/dark)

#### FR-4.9.2 Data Management
- Export all data (JSON backup)
- Import data from backup
- Clear historical data (by academic year)

#### FR-4.9.3 Academic Year Templates
- Copy academic year structure (holidays) to new year
- Clone module structure for new academic year

---

## 5. Non-Functional Requirements

### 5.1 Performance
| Metric | Target | Notes |
|--------|--------|-------|
| Application launch | < 3 seconds | Cold start |
| API response time | < 1 second | 95th percentile, depends on network |
| Search results | < 500ms | After initial load |
| Calendar rendering | < 200ms | Month view with 50+ sessions |
| Data capacity | 5+ years | Historical data retained |

### 5.2 Availability
- **Dependency on MongoDB Atlas**: 99.95% SLA (free tier has no SLA guarantee)
- **Graceful degradation**: Show cached data header information if connection fails
- **Retry logic**: Automatic retry with exponential backoff for failed requests
- **Connection status**: Always visible indicator (online/offline/syncing)

### 5.3 Usability
- Intuitive navigation with minimal training
- Keyboard shortcuts for common actions:
  - `Ctrl+N` — New session
  - `Ctrl+S` — Save current item
  - `Ctrl+K` — Global search
  - `Esc` — Close modal/go back
- Responsive layout:
  - Minimum: 1024x768 (desktop)
  - Web: Responsive down to 768px width
- Accessibility compliance (WCAG 2.1 AA)
- Clear connection status indicator
- Confirmation dialogs for destructive actions

### 5.4 Reliability
- **Requires internet connection** (cloud-based, no offline mode in v1.0)
- Graceful error handling for network failures
- Clear, actionable error messages in Catalan
- Data validation before submission (client-side)
- Server-side validation via MongoDB schema validation
- **Automatic save**: Changes saved within 2 seconds of edit
- **Future (v2.0)**: Offline mode with local cache and sync

### 5.5 Security
| Aspect | Implementation |
|--------|----------------|
| API credentials | Environment variables, never in source control |
| Transport | HTTPS only (TLS 1.2+) |
| Data at rest | MongoDB Atlas encryption (AES-256) |
| Sensitive data | No student PII stored (names, grades, etc.) |
| Input validation | Sanitize all user inputs |
| **Future (v2.0)** | User authentication, role-based access |

### 5.6 Maintainability
- Comprehensive logging (errors, API calls, user actions)
- Modular codebase following Clean Architecture
- Unit test coverage > 70%
- Widget test coverage > 50%
- Documentation for all public APIs
- Code linting enforced (flutter_lints)
- Git version control with conventional commits

### 5.7 Portability
| Platform | Build Target | Distribution |
|----------|--------------|--------------|
| Windows | x64 | `.exe` installer or `.msix` |
| macOS | Universal (Intel + Apple Silicon) | `.dmg` or App Store |
| Linux | x64 | `.deb`, `.AppImage`, or Snap |
| Web | Modern browsers | Static hosting (Netlify, Vercel, GitHub Pages) |

### 5.8 Browser Compatibility (Web Version)
| Browser | Minimum Version |
|---------|-----------------|
| Chrome | 88+ |
| Firefox | 85+ |
| Safari | 14+ |
| Edge | 88+ |

**Note**: Internet Explorer is not supported.

### 5.9 Language
- **Interface language**: Català (single language, no i18n overhead)
- Date format: dd/MM/yyyy
- Time format: 24h

### 5.10 Data Retention and Backup
- **Cloud backups**: MongoDB Atlas automated daily backups (free tier: last 2 days)
- **User-initiated export**: Full JSON export available anytime
- **Data retention**: User controls when to archive/delete academic years
- **No automatic deletion**: Data persists until user explicitly removes it

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
├── vacationPeriods: List<VacationPeriod>  # Períodes de vacances específics d'aquest curs
├── isActive: Boolean
└── createdAt: DateTime

VacationPeriod (Períodes de vacances específics del curs acadèmic)
├── id: String (UUID)
├── name: String (e.g., "Vacances de Nadal", "Setmana Santa")
├── startDate: DateTime
├── endDate: DateTime
└── note: String (optional)

RecurringHoliday (Festius que es repeteixen cada any - CONFIGURAT UNA VEGADA)
├── id: String (UUID)
├── name: String (e.g., "Nadal", "Cap d'Any", "Diada Nacional")
├── month: Integer (1-12)
├── day: Integer (1-31)
├── isEnabled: Boolean (per poder desactivar sense esborrar)
└── createdAt: DateTime

Group (Representa una classe d'alumnes)
├── id: String (UUID)
├── academicYearId: String (FK)
├── name: String (e.g., "DAW1-A", "SMX2-B")
├── notes: String
└── createdAt: DateTime

Modul (Professional Module - definició del mòdul)
├── id: String (UUID)
├── academicYearId: String (FK)
├── code: String (e.g., "MP06")
├── name: String (e.g., "Desenvolupament Web en Entorn Client")
├── description: String
├── totalHours: Integer
├── objectives: List<String>
├── officialReference: String (optional, link to curriculum)
└── createdAt: DateTime

GrupModul (Assignació: quin grup cursa quin mòdul, quan i amb quin horari)
├── id: String (UUID)
├── groupId: String (FK)
├── modulId: String (FK)
├── startDate: DateTime (when this group starts this module)
├── schedule: List<ScheduleSlot>
├── room: String (default room for this group+module)
├── notes: String
└── createdAt: DateTime

ScheduleSlot (Franges horàries setmanals)
├── dayOfWeek: Integer (1=Dilluns, 5=Divendres)
├── startTime: Time (e.g., "15:00")
├── endTime: Time (e.g., "18:00")
└── durationMinutes: Integer (calculated or explicit)

ResultatAprenentatge (RA - Learning Outcome, linked to Modul)
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

RASchedule (Dates per cada RA, per cada GrupModul - calculades o manuals)
├── id: String (UUID)
├── grupModulId: String (FK) ◄── CLAU: referencia la combinació Grup+Mòdul
├── raId: String (FK)
│
│   # Dates calculades automàticament
├── calculatedStartDate: DateTime
├── calculatedEndDate: DateTime
├── calculatedSessions: Integer
├── calculatedHours: Integer
│
│   # Dates manuals (si el professor les sobreescriu)
├── isManuallyOverridden: Boolean (default: false)
├── manualStartDate: DateTime (nullable - only if overridden)
├── manualEndDate: DateTime (nullable - only if overridden)
├── manualAdjustmentNotes: String (nullable - motiu de l'ajustament)
│
│   # Dates efectives (les que s'utilitzen realment)
│   # Si isManuallyOverridden: usa manualStart/EndDate
│   # Si no: usa calculatedStart/EndDate
│
│   # Informació sobre hores perdudes per festius
├── holidaySessionsLost: Integer (sessions perdudes per festius)
├── holidayHoursLost: Integer (hores perdudes per festius)
├── holidaysInPeriod: List<String> (noms dels festius afectats)
│
├── status: Enum [pending, in_progress, completed]
├── lastCalculatedAt: DateTime
└── overriddenAt: DateTime (nullable - when manually changed)

# NOTA: Les dates efectives es calculen així:
# effectiveStartDate = isManuallyOverridden ? manualStartDate : calculatedStartDate
# effectiveEndDate = isManuallyOverridden ? manualEndDate : calculatedEndDate
#
# COMPORTAMENT EN RECALCULAR:
# - Si isManuallyOverridden = false: les dates efectives s'actualitzen
# - Si isManuallyOverridden = true: les dates calculades s'actualitzen però
#   les dates efectives NO canvien. Es mostra un avís al professor indicant
#   que les dates calculades han canviat però les manuals es mantenen.
# - El professor pot fer "Reset to calculated" per tornar a usar les dates calculades

Session (Sessió individual de classe)
├── id: String (UUID)
├── grupModulId: String (FK) ◄── Identifica grup+mòdul
├── raScheduleId: String (FK) ◄── A quin RA pertany
├── date: DateTime
├── startTime: Time
├── endTime: Time
├── room: String (can override GrupModul default)
├── plannedContent: PlannedContent
├── actualContent: ActualContent (nullable)
├── status: Enum [planned, completed, cancelled]
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
├── sessionId: String (FK, optional - can be linked to session)
├── grupModulId: String (FK) ◄── Required: always linked to grup+modul
├── raId: String (FK, optional)
├── title: String
├── description: String
├── dueDate: DateTime
├── estimatedEffort: Integer (minutes)
├── relatedCriteris: List<String> (CA codes)
├── status: Enum [assigned, reviewed, archived]
├── reviewNotes: String
└── createdAt: DateTime

UserSettings (Single document per user)
├── id: String (UUID)
├── theme: Enum [light, dark, system]
├── defaultSessionDuration: Integer (minutes)
├── defaultModulStartMonth: Integer (1-12, typically 9 for September)
├── showCompletedSessions: Boolean
├── dashboardWidgets: List<String> (widget IDs to display)
└── updatedAt: DateTime

SessionTemplate
├── id: String (UUID)
├── name: String
├── description: String
├── defaultDuration: Integer (minutes)
├── defaultTopics: List<String>
├── defaultActivities: List<String>
├── defaultMaterials: List<Resource>
├── tags: List<String>
└── createdAt: DateTime
```

### 6.2 RA Date Calculation Algorithm

```
┌─────────────────────────────────────────────────────────────────┐
│                  RA DATE CALCULATION LOGIC                       │
└─────────────────────────────────────────────────────────────────┘

INPUT: GrupModul (la combinació grup + mòdul amb horari i data d'inici)

FUNCTION calculateRASchedule(grupModul):
    modul = getModul(grupModul.modulId)
    academicYear = getAcademicYear(grupModul.academicYearId)
    
    # Get all non-teaching days
    recurringHolidays = getRecurringHolidays()  # From global config
    vacationPeriods = academicYear.vacationPeriods
    
    currentDate = grupModul.startDate
    
    FOR EACH ra IN modul.ras ORDER BY ra.order:
        
        # Check if this RA has manual override - if so, skip calculation
        existingSchedule = getRASchedule(grupModul.id, ra.id)
        IF existingSchedule AND existingSchedule.isManuallyOverridden:
            currentDate = nextDay(existingSchedule.manualEndDate)
            CONTINUE  # Keep manual dates, move to next RA
        
        # Find first valid session date (skipping holidays)
        startDate = findNextValidSessionDate(currentDate, grupModul.schedule, 
                                              recurringHolidays, vacationPeriods)
        
        # Calculate sessions needed
        sessionDuration = getSessionDuration(grupModul.schedule)  # in minutes
        sessionsNeeded = CEILING(ra.durationHours * 60 / sessionDuration)
        
        # Calculate end date by iterating through sessions
        endDate = startDate
        sessionsScheduled = 0
        holidaySessionsLost = 0
        
        WHILE sessionsScheduled < sessionsNeeded:
            IF isScheduledDay(endDate, grupModul.schedule):
                IF isHoliday(endDate, recurringHolidays) OR isInVacation(endDate, vacationPeriods):
                    holidaySessionsLost++  # Count lost session
                    endDate = nextDay(endDate)
                ELSE:
                    sessionsScheduled++
                    IF sessionsScheduled < sessionsNeeded:
                        endDate = nextDay(endDate)
            ELSE:
                endDate = nextDay(endDate)
        
        # Create or update RASchedule record
        UPSERT RASchedule(
            grupModulId: grupModul.id,
            raId: ra.id,
            calculatedStartDate: startDate,
            calculatedEndDate: endDate,
            calculatedSessions: sessionsNeeded,
            calculatedHours: sessionsNeeded * sessionDuration / 60,
            holidaySessionsLost: holidaySessionsLost,
            holidayHoursLost: holidaySessionsLost * sessionDuration / 60,
            isManuallyOverridden: false,
            lastCalculatedAt: NOW()
        )
        
        # Set next RA start after this one ends
        currentDate = nextDay(endDate)
    
    RETURN allRASchedules

# Check if a date is a recurring holiday
FUNCTION isHoliday(date, recurringHolidays):
    FOR EACH holiday IN recurringHolidays:
        IF holiday.isEnabled AND date.month == holiday.month AND date.day == holiday.day:
            RETURN true
    RETURN false

# Check if a date falls within any vacation period
FUNCTION isInVacation(date, vacationPeriods):
    FOR EACH vacation IN vacationPeriods:
        IF date >= vacation.startDate AND date <= vacation.endDate:
            RETURN true
    RETURN false

# Find next valid session date (not a holiday, not in vacation, and is a scheduled day)
FUNCTION findNextValidSessionDate(fromDate, schedule, recurringHolidays, vacationPeriods):
    date = fromDate
    WHILE true:
        IF isScheduledDay(date, schedule) 
           AND NOT isHoliday(date, recurringHolidays) 
           AND NOT isInVacation(date, vacationPeriods):
            RETURN date
        date = nextDay(date)

# Recalculate only non-overridden RAs from a certain point
FUNCTION recalculateFromRA(grupModul, modifiedRA, preserveOverrides = true):
    modul = getModul(grupModul.modulId)
    FOR EACH ra IN modul.ras WHERE ra.order >= modifiedRA.order:
        existingSchedule = getRASchedule(grupModul.id, ra.id)
        IF preserveOverrides AND existingSchedule AND existingSchedule.isManuallyOverridden:
            CONTINUE  # Skip manually overridden RAs
        recalculate(grupModul, ra)

# Helper: Get total session duration per week for a GrupModul
FUNCTION getWeeklyHours(grupModul):
    RETURN SUM(slot.durationMinutes FOR slot IN grupModul.schedule) / 60

# Helper: Get effective dates (manual if overridden, calculated otherwise)
FUNCTION getEffectiveDates(raSchedule):
    IF raSchedule.isManuallyOverridden:
        RETURN (raSchedule.manualStartDate, raSchedule.manualEndDate)
    ELSE:
        RETURN (raSchedule.calculatedStartDate, raSchedule.calculatedEndDate)
```

### 6.3 Entity Relationship Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                     ENTITY RELATIONSHIP DIAGRAM                              │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐                                    
│   AcademicYear   │                                    
│──────────────────│                                    
│ id               │◄─────────────────┬────────────────┐
│ name             │                  │                │
│ startDate        │                  │                │
│ endDate          │                  │                │
│ vacationPeriods[]│ ◄── Embedded    │                │
│   ├─ name        │     (Nadal,     │                │
│   ├─ startDate   │     Setmana     │                │
│   └─ endDate     │     Santa...)   │                │
└──────────────────┘                  │                │
                                      │                │
         ┌────────────────────────────┘                │
         │ 1:N                                         │ 1:N
         ▼                                             ▼
┌──────────────┐                          ┌──────────────┐
│    Group     │                          │    Modul     │
│──────────────│                          │──────────────│
│ id           │                          │ id           │
│ academicYear │                          │ academicYear │
│ name         │                          │ code         │
│ notes        │                          │ name         │
└──────┬───────┘                          │ totalHours   │
       │                                  └──────┬───────┘
       │                                         │
       │ 1:N                                     │ 1:N
       │         ┌───────────────┐               │
       └────────►│   GrupModul   │◄──────────────┘
                 │───────────────│
                 │ id            │
                 │ groupId    (FK)│
                 │ modulId    (FK)│
                 │ startDate     │
                 │ schedule[]    │
                 │ room          │
                 └───────┬───────┘
                         │
                         │ 1:N
                         ▼
                 ┌───────────────┐         ┌──────────────┐
                 │  RASchedule   │         │      RA      │
                 │───────────────│         │──────────────│
                 │ id            │         │ id           │
                 │ grupModulId(FK)│◄───────│ modulId  (FK)│
                 │ raId      (FK)│────────►│ number       │
                 │ startDate     │   N:1   │ durationHours│
                 │ endDate       │         │ order        │
                 │ sessionsCount │         │ criteris[]   │
                 │ status        │         └──────────────┘
                 └───────┬───────┘
                         │
                         │ 1:N
                         ▼
                 ┌───────────────┐
                 │    Session    │
                 │───────────────│
                 │ id            │
                 │ grupModulId(FK)│
                 │ raScheduleId(FK)│
                 │ date          │
                 │ plannedContent│
                 │ actualContent │
                 │ status        │
                 └───────┬───────┘
                         │
                         │ 1:N (optional)
                         ▼
                 ┌───────────────┐
                 │   Homework    │
                 │───────────────│
                 │ grupModulId(FK)│
                 │ sessionId (FK)│
                 │ title         │
                 │ dueDate       │
                 └───────────────┘

RELACIONS CLAU:
───────────────
• Group (N) ◄──► GrupModul ◄──► (N) Modul  [Many-to-Many via GrupModul]
• GrupModul (1) ──► (N) RASchedule         [Un GrupModul té N RASchedules]
• RA (1) ◄── (N) RASchedule                [Cada RA pot tenir múltiples schedules per diferents grups]
• RASchedule (1) ──► (N) Session           [Un RASchedule té N Sessions]
• RecurringHoliday: Independent, aplicat a tots els cursos acadèmics
• VacationPeriod: Embedded dins AcademicYear, específic per cada curs

ENTITATS INDEPENDENTS (No relacionades directament):
────────────────────────────────────────────────────
┌─────────────────────┐
│  RecurringHoliday   │  ◄── Configurat UNA VEGADA, s'aplica a TOTS els cursos
│─────────────────────│
│ id                  │
│ name                │
│ month (1-12)        │
│ day (1-31)          │
│ isEnabled           │
└─────────────────────┘

Exemple: 25/12 Nadal, 01/01 Cap d'Any, 11/09 Diada...
```

### 6.4 Document Collections (MongoDB)

| Collection          | Description                                | Indexes                                 | Est. Size |
|---------------------|--------------------------------------------|-----------------------------------------|-----------|
| recurring_holidays  | **Festius recurrents (configurats una vegada)** | `month`, `day`, `isEnabled`         | ~15 docs  |
| academic_years      | Cursos acadèmics amb períodes de vacances  | `isActive`, `startDate`                 | ~10 docs  |
| groups              | Grups d'alumnes (DAW1-A, SMX2-B...)        | `academicYearId`, `name`                | ~20 docs  |
| moduls              | Mòduls professionals                       | `academicYearId`, `code`                | ~50 docs  |
| grup_moduls         | **Assignacions grup+mòdul amb horari**     | `groupId`, `modulId`, `startDate`       | ~100 docs |
| ras                 | Resultats d'Aprenentatge                   | `modulId`, `order`                      | ~200 docs |
| ra_schedules        | Dates per RA (calculades o manuals)        | `grupModulId`, `raId`, `isManuallyOverridden` | ~500 docs |
| sessions            | Sessions de classe individuals             | `grupModulId`, `raScheduleId`, `date`   | ~2000 docs|
| homework            | Tasques                                    | `grupModulId`, `dueDate`, `status`      | ~500 docs |
| session_templates   | Plantilles de sessió reutilitzables        | `tags`, `name`                          | ~50 docs  |
| user_settings       | Preferències d'usuari                      | `_id`                                   | 1 doc     |

**Notes:**
- `recurring_holidays`: Independent collection, not tied to any academic year. Configured once.
- `academic_years.vacationPeriods`: Embedded array for vacation periods specific to each year.
- `ra_schedules`: Contains both calculated and manual dates; `isManuallyOverridden` flag determines which to use.

**Estimated total size:** < 10MB (well within 512MB free tier)

### 6.5 MongoDB Atlas Free Tier Limits

| Resource | Limit | Our Usage |
|----------|-------|-----------|
| Storage | 512 MB | < 10 MB estimated |
| Connections | 500 | 1-3 (single user) |
| Data API requests | 25,000/month | ~5,000 estimated |
| Network transfer | 10 GB/month | < 1 GB estimated |

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
│   │   │   └── atlas_config.dart       # MongoDB Atlas configuration
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── extensions/
│   │   ├── network/
│   │   │   └── atlas_client.dart       # HTTP client wrapper for Atlas Data API
│   │   ├── theme/
│   │   └── utils/
│   │       └── date_calculator.dart    # RA date calculation utilities
│   │
│   ├── data/
│   │   ├── datasources/
│   │   │   └── remote/                 # MongoDB Atlas Data API
│   │   │       ├── academic_year_remote_ds.dart
│   │   │       ├── group_remote_ds.dart
│   │   │       ├── modul_remote_ds.dart
│   │   │       ├── grup_modul_remote_ds.dart   # ◄── NEW
│   │   │       ├── ra_remote_ds.dart
│   │   │       ├── ra_schedule_remote_ds.dart
│   │   │       └── session_remote_ds.dart
│   │   ├── models/
│   │   │   ├── academic_year_model.dart
│   │   │   ├── group_model.dart
│   │   │   ├── modul_model.dart
│   │   │   ├── grup_modul_model.dart           # ◄── NEW
│   │   │   ├── schedule_slot_model.dart
│   │   │   ├── ra_model.dart
│   │   │   ├── ca_model.dart                   # Criteris d'Avaluació
│   │   │   ├── ra_schedule_model.dart
│   │   │   ├── session_model.dart
│   │   │   └── homework_model.dart
│   │   └── repositories/
│   │       ├── academic_year_repository_impl.dart
│   │       ├── group_repository_impl.dart
│   │       ├── modul_repository_impl.dart
│   │       ├── grup_modul_repository_impl.dart # ◄── NEW
│   │       ├── ra_repository_impl.dart
│   │       └── session_repository_impl.dart
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── academic_year.dart
│   │   │   ├── group.dart
│   │   │   ├── modul.dart
│   │   │   ├── grup_modul.dart                 # ◄── NEW
│   │   │   ├── ra.dart
│   │   │   ├── ra_schedule.dart
│   │   │   └── session.dart
│   │   ├── repositories/
│   │   │   ├── academic_year_repository.dart
│   │   │   ├── group_repository.dart
│   │   │   ├── modul_repository.dart
│   │   │   ├── grup_modul_repository.dart      # ◄── NEW
│   │   │   ├── ra_repository.dart
│   │   │   └── session_repository.dart
│   │   └── usecases/
│   │       ├── academic_year/
│   │       ├── group/
│   │       ├── modul/
│   │       ├── grup_modul/                     # ◄── NEW
│   │       │   ├── create_grup_modul_usecase.dart
│   │       │   └── get_grup_moduls_by_group_usecase.dart
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
│   │       │   └── connection_status_widget.dart  # Online/offline indicator
│   │       └── specific/
│   │           ├── ra_timeline_widget.dart
│   │           ├── ra_card_widget.dart
│   │           └── ca_checklist_widget.dart
│   │
│   └── services/
│       ├── ra_schedule_service.dart    # RA date calculation service
│       └── export_service.dart
│
├── test/
│   ├── unit/
│   │   ├── ra_date_calculation_test.dart
│   │   └── atlas_client_test.dart
│   ├── widget/
│   └── integration/
│
├── web/                        # Flutter web specific
│   └── index.html
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
**Goal:** Working skeleton with database connection

- [ ] Project setup (Flutter, folder structure, linting)
- [ ] **MongoDB Atlas cluster setup (free tier M0)**
- [ ] **Enable Atlas Data API and create API key**
- [ ] Core entity models with JSON serialization
- [ ] Atlas HTTP client wrapper with error handling
- [ ] Basic CRUD operations for Academic Year
- [ ] Navigation shell with placeholder pages
- [ ] Connection status indicator widget

**Deliverable:** App launches, connects to Atlas, can create/list academic years

### Phase 2: Core Structure (Weeks 4-6)
**Goal:** Complete academic structure management

- [ ] Academic year management (CRUD, holidays)
- [ ] Group management (CRUD - just group names/notes)
- [ ] Module management (CRUD, link to academic year)
- [ ] RA management (CRUD, ordering, duration)
- [ ] **GrupModul management (assign modules to groups with schedules)**
- [ ] **RA date auto-calculation service (triggered by GrupModul)**
- [ ] RA hours validation (sum vs module total)
- [ ] RASchedule generation per GrupModul
- [ ] RA timeline visualization widget

**Deliverable:** Can assign modules to groups, RA dates auto-calculate

### Phase 3: Session Management (Weeks 7-9)
**Goal:** Plan and track sessions

- [ ] Calendar view (month/week/day)
- [ ] Session creation and editing
- [ ] Session linking to RA
- [ ] Planned content entry
- [ ] Session annotation (actual content)
- [ ] CA tracking per session
- [ ] Copy/duplicate sessions
- [ ] Session templates (CRUD)

**Deliverable:** Full session planning and tracking workflow

### Phase 4: Extended Features (Weeks 10-11)
**Goal:** Complete feature set

- [ ] Homework management (CRUD, linking)
- [ ] Progress tracking per RA/module
- [ ] Dashboard with widgets
- [ ] Global search and filtering
- [ ] Quick access panel
- [ ] Alerts (behind schedule, hours mismatch)

**Deliverable:** Feature-complete application

### Phase 5: Polish & Deploy (Weeks 12-14)
**Goal:** Production-ready release

- [ ] Reporting and PDF export
- [ ] CSV/JSON data export
- [ ] Settings and preferences
- [ ] Testing (unit, widget, integration)
- [ ] Bug fixes and performance tuning
- [ ] Documentation (README, user guide)
- [ ] **Desktop builds** (Windows, macOS, Linux)
- [ ] **Web deployment** (Netlify/Vercel)

**Deliverable:** Released v1.0 for all platforms

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
  
  # HTTP / MongoDB Atlas Data API
  http: ^1.1.0
  dio: ^5.4.0              # Alternative with better features
  
  # Routing
  go_router: ^13.0.0
  
  # UI Components
  flutter_adaptive_scaffold: ^0.1.0
  table_calendar: ^3.0.9
  syncfusion_flutter_calendar: ^24.0.0  # Alternative
  
  # Utilities
  uuid: ^4.2.0
  intl: ^0.18.0
  json_annotation: ^4.8.1  # For JSON serialization
  connectivity_plus: ^5.0.0 # Check online status
  
  # Export
  pdf: ^3.10.0
  printing: ^5.11.0
  csv: ^5.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  json_serializable: ^6.7.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0
  flutter_lints: ^3.0.0
```

### 10.1 MongoDB Atlas Data API Configuration

```dart
// lib/core/constants/atlas_config.dart

class AtlasConfig {
  // Development configuration - single user, no auth
  // TODO: Move to environment variables for production
  
  static const String appId = 'data-xxxxx';  // From Atlas App Services
  static const String apiKey = 'your-api-key-here';
  static const String baseUrl = 'https://data.mongodb-api.com/app/$appId/endpoint/data/v1';
  
  static const String dataSource = 'Cluster0';
  static const String database = 'class_activity_manager';
  
  // Collections
  static const String academicYearsCollection = 'academic_years';
  static const String modulsCollection = 'moduls';
  static const String rasCollection = 'ras';
  static const String groupsCollection = 'groups';
  static const String raSchedulesCollection = 'ra_schedules';
  static const String sessionsCollection = 'sessions';
  static const String homeworkCollection = 'homework';
}
```

### 10.2 Example Data Source Implementation

```dart
// lib/data/datasources/remote/modul_remote_ds.dart

class ModulRemoteDataSource {
  final http.Client client;
  
  ModulRemoteDataSource(this.client);
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'api-key': AtlasConfig.apiKey,
  };
  
  Future<List<ModulModel>> getModulsByYear(String academicYearId) async {
    final response = await client.post(
      Uri.parse('${AtlasConfig.baseUrl}/action/find'),
      headers: _headers,
      body: jsonEncode({
        'dataSource': AtlasConfig.dataSource,
        'database': AtlasConfig.database,
        'collection': AtlasConfig.modulsCollection,
        'filter': {'academicYearId': academicYearId},
        'sort': {'code': 1},
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['documents'] as List)
          .map((doc) => ModulModel.fromJson(doc))
          .toList();
    } else {
      throw ServerException('Failed to fetch moduls: ${response.statusCode}');
    }
  }
  
  Future<ModulModel> createModul(ModulModel modul) async {
    final response = await client.post(
      Uri.parse('${AtlasConfig.baseUrl}/action/insertOne'),
      headers: _headers,
      body: jsonEncode({
        'dataSource': AtlasConfig.dataSource,
        'database': AtlasConfig.database,
        'collection': AtlasConfig.modulsCollection,
        'document': modul.toJson(),
      }),
    );
    
    if (response.statusCode == 201) {
      return modul;
    } else {
      throw ServerException('Failed to create modul: ${response.statusCode}');
    }
  }
  
  Future<void> updateModul(ModulModel modul) async {
    await client.post(
      Uri.parse('${AtlasConfig.baseUrl}/action/updateOne'),
      headers: _headers,
      body: jsonEncode({
        'dataSource': AtlasConfig.dataSource,
        'database': AtlasConfig.database,
        'collection': AtlasConfig.modulsCollection,
        'filter': {'_id': {'\$oid': modul.id}},
        'update': {'\$set': modul.toJson()},
      }),
    );
  }
}
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

1. **User Authentication** - Login system for multiple teachers
2. **Offline Mode** - Local cache with sync when back online
3. **Student Roster** - Basic student list per group (no grades)
4. **Collaboration** - Share modules with other teachers
5. **Templates Marketplace** - Community session templates
6. **Analytics Dashboard** - Teaching pattern insights
7. **Mobile Companion** - Read-only mobile app for quick reference
8. **AI Suggestions** - Smart scheduling and pacing recommendations
9. **Integration APIs** - Connect with LMS platforms

---

## 13. Glossari

| Terme                        | Definició                                                                           |
|------------------------------|------------------------------------------------------------------------------------|
| Curs Acadèmic                | El període lectiu complet, típicament de setembre a juny                           |
| Cicle Formatiu               | Un programa complet de formació professional (p.ex. DAW, SMX, ASIX)                |
| Mòdul Professional (MP)      | Una assignatura dins d'un cicle formatiu (p.ex. "MP06 - Desenvolupament Web")      |
| Resultat d'Aprenentatge (RA) | Un objectiu d'aprenentatge mesurable dins d'un mòdul; els RAs són consecutius      |
| Criteri d'Avaluació (CA)     | Criteris específics per avaluar l'assoliment d'un RA                               |
| Grup                         | Una classe específica d'alumnes (p.ex. "DAW1-A"); pot cursar múltiples mòduls      |
| **GrupModul**                | **Assignació d'un mòdul a un grup, amb horari i data d'inici específics**          |
| **RecurringHoliday**         | **Festiu recurrent (mateixa data cada any): Nadal, Diada, etc. Configurat una vegada** |
| **VacationPeriod**           | **Període de vacances específic d'un curs acadèmic (Nadal, Setmana Santa)**        |
| Sessió                       | Una classe individual                                                               |
| Horari (Schedule)            | Les franges horàries setmanals per a un GrupModul específic                        |
| Contingut Planificat         | El que el professor preveu tractar en una sessió                                   |
| Contingut Real               | El que realment s'ha tractat, registrat després de la sessió                       |
| Tasca                        | Treball assignat als alumnes fora de classe                                        |
| RASchedule                   | Dates d'inici/fi per cada RA d'un GrupModul; calculades automàticament però editables manualment |
| **isManuallyOverridden**     | **Indica si el professor ha modificat manualment les dates d'un RASchedule**       |

---

## 14. Acceptance Criteria

The project will be considered complete (v1.0) when:

### Functional Completeness
- [ ] All functional requirements from Section 4 (FR-4.1 through FR-4.9) are implemented
- [ ] RA date auto-calculation works correctly with holidays
- [ ] Data persists correctly in MongoDB Atlas
- [ ] Export to PDF and CSV functions work

### Platform Support
- [ ] Application runs on Windows 10/11 (x64)
- [ ] Application runs on macOS 12+ (Intel and Apple Silicon)
- [ ] Application runs on Ubuntu 22.04+ (x64)
- [ ] Application runs on modern web browsers (Chrome, Firefox, Safari, Edge)
- [ ] Data syncs correctly across all platforms (same MongoDB database)

### Quality
- [ ] Test coverage meets targets: Domain > 70%, Data > 60%, Overall > 50%
- [ ] No critical (P0) or high-severity (P1) bugs remain open
- [ ] Application launches in < 3 seconds
- [ ] API responses complete in < 2 seconds (95th percentile)

### Documentation
- [ ] README with setup instructions
- [ ] User guide (basic usage documentation)
- [ ] MongoDB Atlas setup guide (Appendix A)

### Security
- [ ] API key is not committed to source control
- [ ] All API calls use HTTPS
- [ ] No sensitive student data is stored

---

## Appendix A: MongoDB Atlas Setup Guide

### A.1 Create MongoDB Atlas Account and Cluster

1. Go to [https://www.mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas)
2. Create a free account
3. Create a new cluster:
   - Select **M0 Sandbox (Free)**
   - Choose a cloud provider (AWS/GCP/Azure)
   - Select a region close to you (e.g., `eu-west-1` for Spain)
   - Name your cluster (e.g., `ClassActivityCluster`)

### A.2 Configure Network Access

1. Go to **Security → Network Access**
2. Click **Add IP Address**
3. For development, select **Allow Access from Anywhere** (0.0.0.0/0)
   - ⚠️ For production, restrict to specific IPs

### A.3 Enable Data API

1. Go to **App Services** (left sidebar)
2. Click **Create a New App**
3. Name it (e.g., `ClassActivityAPI`)
4. Link to your cluster
5. Go to **HTTPS Endpoints** → **Data API**
6. Enable the Data API
7. Copy your **App ID** (looks like `data-xxxxx`)

### A.4 Create API Key

1. In App Services, go to **Authentication**
2. Enable **API Keys** provider
3. Go to **App Users** → **Authentication Providers** → **API Keys**
4. Create a new API key
5. Copy and save the key securely (shown only once!)

### A.5 Create Database and Collections

1. Go to **Atlas** → **Browse Collections**
2. Create database: `class_activity_manager`
3. Create collections:
   - `academic_years`
   - `moduls`
   - `ras`
   - `groups`
   - `ra_schedules`
   - `sessions`
   - `homework`

### A.6 Configure Flutter App

Create `lib/core/constants/atlas_config.dart`:

```dart
class AtlasConfig {
  // ⚠️ For development only - move to environment variables for production
  static const String appId = 'data-xxxxx';        // Your App ID
  static const String apiKey = 'your-api-key';     // Your API Key
  
  static const String baseUrl = 
      'https://eu-west-2.aws.data.mongodb-api.com/app/$appId/endpoint/data/v1';
  
  static const String dataSource = 'ClassActivityCluster';
  static const String database = 'class_activity_manager';
}
```

### A.7 Test Connection

```dart
// Quick test - run in main.dart temporarily
void testAtlasConnection() async {
  final response = await http.post(
    Uri.parse('${AtlasConfig.baseUrl}/action/find'),
    headers: {
      'Content-Type': 'application/json',
      'api-key': AtlasConfig.apiKey,
    },
    body: jsonEncode({
      'dataSource': AtlasConfig.dataSource,
      'database': AtlasConfig.database,
      'collection': 'moduls',
      'filter': {},
    }),
  );
  
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
}
```

### A.8 Data API Quick Reference

| Operation | Endpoint | Body |
|-----------|----------|------|
| Find all | `/action/find` | `{filter: {}}` |
| Find one | `/action/findOne` | `{filter: {_id: ...}}` |
| Insert one | `/action/insertOne` | `{document: {...}}` |
| Insert many | `/action/insertMany` | `{documents: [...]}` |
| Update one | `/action/updateOne` | `{filter: {...}, update: {...}}` |
| Delete one | `/action/deleteOne` | `{filter: {...}}` |

---

*Document prepared for educational and development purposes.*