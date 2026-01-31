# Class Activity Manager - UML Diagrams

**Version:** 1.0
**Date:** 2026-01-30
**Based on:** Prototype v0.1

---

## Table of Contents

1. [Use Case Diagram](#1-use-case-diagram)
2. [Sequence Diagrams](#2-sequence-diagrams)
   - 2.1 [Import Curriculum Modules](#21-import-curriculum-modules)
   - 2.2 [Create Module Manually](#22-create-module-manually)
   - 2.3 [Add RA to Module](#23-add-ra-to-module)
   - 2.4 [Configure RA Dates](#24-configure-ra-dates)
   - 2.5 [Enter Daily Notes](#25-enter-daily-notes)
   - 2.6 [Manage Academic Year](#26-manage-academic-year)
   - 2.7 [Manage Groups](#27-manage-groups)

---

## 1. Use Case Diagram

```
+===========================================================================+
|                      CLASS ACTIVITY MANAGER                                |
|                         Use Case Diagram                                   |
+===========================================================================+

                                    +----------------------------------+
                                    |           <<system>>             |
                                    |    Class Activity Manager        |
                                    +----------------------------------+
                                    |                                  |
     +--------+                     |  +----------------------------+  |
     | Teacher|                     |  |   Module Management        |  |
     | (Actor)|                     |  +----------------------------+  |
     +---+----+                     |  |                            |  |
         |                          |  | (UC01) Import Curriculum   |  |
         |                          |  |         Modules            |  |
         +------------------------->|  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC02) Create Module       |  |
         |                          |  |         Manually           |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC03) Edit Module         |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC04) Delete Module       |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         |                          |  |   RA Management            |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC05) Add RA to Module    |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC06) Edit RA             |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC07) Delete RA           |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC08) Configure RA Dates  |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         |                          |  |   Session Tracking         |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC09) Enter Daily Notes   |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC10) Mark Session        |  |
         |                          |  |         Complete           |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         |                          |  |   Configuration            |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC11) Set Academic Year   |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC12) Manage Vacation     |  |
         |                          |  |         Periods            |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC13) Manage Recurring    |  |
         |                          |  |         Holidays           |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         |                          |  |   Group Management         |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC14) Create Group        |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC15) Edit Group          |  |
         |                          |  +----------------------------+  |
         |                          |                                  |
         |                          |  +----------------------------+  |
         +------------------------->|  | (UC16) View Dashboard      |  |
                                    |  +----------------------------+  |
                                    |                                  |
                                    +----------------------------------+


    +==================================================================+
    |                    USE CASE RELATIONSHIPS                         |
    +==================================================================+

    UC01 (Import Curriculum Modules)
         |
         +--<<include>>--> Select Cycles
         |
         +--<<include>>--> Select Modules
         |
         +--<<include>>--> Auto-generate RAs from UFs

    UC09 (Enter Daily Notes)
         |
         +--<<include>>--> Select Module
         |
         +--<<include>>--> Select RA
         |
         +--<<extend>>--> UC10 (Mark Session Complete)

    UC08 (Configure RA Dates)
         |
         +--<<precondition>>--> UC05 or UC01 (RA must exist)

    UC09 (Enter Daily Notes)
         |
         +--<<precondition>>--> UC08 (RA dates must be configured)
```

---

## 2. Sequence Diagrams

### 2.1 Import Curriculum Modules

```
+===========================================================================+
|         SEQUENCE DIAGRAM: UC01 - Import Curriculum Modules                |
+===========================================================================+

  Teacher          SetupCurriculumPage      CurriculumService      AppStateNotifier       AppState
     |                    |                       |                      |                   |
     |  Navigate to       |                       |                      |                   |
     |  /setup-curriculum |                       |                      |                   |
     |------------------->|                       |                      |                   |
     |                    |                       |                      |                   |
     |                    |  loadCicles()         |                      |                   |
     |                    |---------------------->|                      |                   |
     |                    |                       |                      |                   |
     |                    |                       |  read YAML           |                   |
     |                    |                       |  (assets/curriculum- |                   |
     |                    |                       |   informatica.yaml)  |                   |
     |                    |                       |----------+           |                   |
     |                    |                       |          |           |                   |
     |                    |                       |<---------+           |                   |
     |                    |                       |                      |                   |
     |                    |  List<CurriculumCicle>|                      |                   |
     |                    |<----------------------|                      |                   |
     |                    |                       |                      |                   |
     |  Display cycles    |                       |                      |                   |
     |  with checkboxes   |                       |                      |                   |
     |<-------------------|                       |                      |                   |
     |                    |                       |                      |                   |
     |  Select cycles     |                       |                      |                   |
     |  (Step 1)          |                       |                      |                   |
     |------------------->|                       |                      |                   |
     |                    |                       |                      |                   |
     |                    |  setSelectedCicles()  |                      |                   |
     |                    |---------------------------------------------->|                   |
     |                    |                       |                      |                   |
     |                    |                       |                      |  update state     |
     |                    |                       |                      |------------------>|
     |                    |                       |                      |                   |
     |  Display modules   |                       |                      |                   |
     |  for selected      |                       |                      |                   |
     |  cycles (Step 2)   |                       |                      |                   |
     |<-------------------|                       |                      |                   |
     |                    |                       |                      |                   |
     |  Select modules    |                       |                      |                   |
     |  to import         |                       |                      |                   |
     |------------------->|                       |                      |                   |
     |                    |                       |                      |                   |
     |  Click "Importa"   |                       |                      |                   |
     |------------------->|                       |                      |                   |
     |                    |                       |                      |                   |
     |                    |     loop [for each selected module]          |                   |
     |                    |     +----------------------------------------+                   |
     |                    |     |                 |                      |                   |
     |                    |     |  importModulFromCurriculum             |                   |
     |                    |     |  (cicleCode, curriculumModul)          |                   |
     |                    |     |-------------------------------------->|                   |
     |                    |     |                 |                      |                   |
     |                    |     |                 |                      |  Create Modul     |
     |                    |     |                 |                      |  with RAs from    |
     |                    |     |                 |                      |  UFs              |
     |                    |     |                 |                      |------------------>|
     |                    |     |                 |                      |                   |
     |                    |     +----------------------------------------+                   |
     |                    |                       |                      |                   |
     |                    |  Navigate to /moduls  |                      |                   |
     |                    |---------------------->|                      |                   |
     |                    |                       |                      |                   |
     |  Show modules list |                       |                      |                   |
     |<-------------------|                       |                      |                   |
     |                    |                       |                      |                   |
```

---

### 2.2 Create Module Manually

```
+===========================================================================+
|           SEQUENCE DIAGRAM: UC02 - Create Module Manually                  |
+===========================================================================+

  Teacher           ModulsListPage        ModulFormPage        AppStateNotifier       AppState
     |                    |                    |                      |                   |
     |  Navigate to       |                    |                      |                   |
     |  /moduls           |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Display modules   |                    |                      |                   |
     |  list              |                    |                      |                   |
     |<-------------------|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Click "+" (FAB)   |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |                    |  Navigate to       |                      |                   |
     |                    |  /moduls/edit/new  |                      |                   |
     |                    |------------------>|                      |                   |
     |                    |                    |                      |                   |
     |  Display empty     |                    |                      |                   |
     |  module form       |                    |                      |                   |
     |<------------------------------------ ---|                      |                   |
     |                    |                    |                      |                   |
     |  Fill form:        |                    |                      |                   |
     |  - code (MP06)     |                    |                      |                   |
     |  - name            |                    |                      |                   |
     |  - description     |                    |                      |                   |
     |  - totalHours      |                    |                      |                   |
     |  - objectives      |                    |                      |                   |
     |----------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |  Click "Desar"     |                    |                      |                   |
     |----------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |                    |                    |  validate form       |                   |
     |                    |                    |----------+           |                   |
     |                    |                    |          |           |                   |
     |                    |                    |<---------+           |                   |
     |                    |                    |                      |                   |
     |                    |                    |  addModul(modul)     |                   |
     |                    |                    |--------------------->|                   |
     |                    |                    |                      |                   |
     |                    |                    |                      |  state.copyWith   |
     |                    |                    |                      |  (moduls: [...])  |
     |                    |                    |                      |------------------>|
     |                    |                    |                      |                   |
     |                    |                    |  Navigate to         |                   |
     |                    |                    |  /moduls/:id         |                   |
     |                    |                    |--------------------->|                   |
     |                    |                    |                      |                   |
     |  Display module    |                    |                      |                   |
     |  detail page       |                    |                      |                   |
     |<--------------------------------------------------|           |                   |
     |                    |                    |                      |                   |
```

---

### 2.3 Add RA to Module

```
+===========================================================================+
|             SEQUENCE DIAGRAM: UC05 - Add RA to Module                      |
+===========================================================================+

  Teacher          ModulDetailPage         RAFormPage          AppStateNotifier       AppState
     |                    |                    |                      |                   |
     |  View module       |                    |                      |                   |
     |  at /moduls/:id    |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Display module    |                    |                      |                   |
     |  details & RAs     |                    |                      |                   |
     |<-------------------|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Click             |                    |                      |                   |
     |  "Afegir RA"       |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |                    |  Navigate to       |                      |                   |
     |                    |  /moduls/:id/ra/new|                      |                   |
     |                    |------------------->|                      |                   |
     |                    |                    |                      |                   |
     |  Display RA form   |                    |                      |                   |
     |<----------------------------------------|                      |                   |
     |                    |                    |                      |                   |
     |  Fill form:        |                    |                      |                   |
     |  - number (1)      |                    |                      |                   |
     |  - code (RA1)      |                    |                      |                   |
     |  - title           |                    |                      |                   |
     |  - description     |                    |                      |                   |
     |  - durationHours   |                    |                      |                   |
     |---------------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |  Click "Desar"     |                    |                      |                   |
     |---------------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |                    |                    |  validate form       |                   |
     |                    |                    |----------+           |                   |
     |                    |                    |          |           |                   |
     |                    |                    |<---------+           |                   |
     |                    |                    |                      |                   |
     |                    |                    |  setModulRA          |                   |
     |                    |                    |  (modulId, ra)       |                   |
     |                    |                    |--------------------->|                   |
     |                    |                    |                      |                   |
     |                    |                    |                      |  Find modul       |
     |                    |                    |                      |  Add RA to        |
     |                    |                    |                      |  modul.ras        |
     |                    |                    |                      |------------------>|
     |                    |                    |                      |                   |
     |                    |                    |  context.pop()       |                   |
     |                    |                    |--------------------->|                   |
     |                    |                    |                      |                   |
     |  Display updated   |                    |                      |                   |
     |  module with       |                    |                      |                   |
     |  new RA            |                    |                      |                   |
     |<-------------------|                    |                      |                   |
     |                    |                    |                      |                   |
```

---

### 2.4 Configure RA Dates

```
+===========================================================================+
|           SEQUENCE DIAGRAM: UC08 - Configure RA Dates                      |
+===========================================================================+

  Teacher          ModulDetailPage         RaConfigPage        AppStateNotifier       AppState
     |                    |                    |                      |                   |
     |  View module       |                    |                      |                   |
     |  at /moduls/:id    |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Click             |                    |                      |                   |
     |  "Configurar dates"|                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |                    |  Navigate to       |                      |                   |
     |                    |  /moduls/:id/      |                      |                   |
     |                    |  ra-config         |                      |                   |
     |                    |------------------>|                      |                   |
     |                    |                    |                      |                   |
     |  Display RAs with  |                    |                      |                   |
     |  date columns      |                    |                      |                   |
     |<------------------------------------ ---|                      |                   |
     |                    |                    |                      |                   |
     |  Click edit on     |                    |                      |                   |
     |  specific RA       |                    |                      |                   |
     |----------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |                    |                    |  showDialog()        |                   |
     |                    |                    |----------+           |                   |
     |                    |                    |          |           |                   |
     |  Display edit      |                    |<---------+           |                   |
     |  dialog            |                    |                      |                   |
     |<------------------------------------ ---|                      |                   |
     |                    |                    |                      |                   |
     |  Set:              |                    |                      |                   |
     |  - durationHours   |                    |                      |                   |
     |  - startDate       |                    |                      |                   |
     |  - endDate         |                    |                      |                   |
     |----------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |  Click "Desar"     |                    |                      |                   |
     |----------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |                    |                    |  setModulRA          |                   |
     |                    |                    |  (modulId,           |                   |
     |                    |                    |   ra.copyWith(...))  |                   |
     |                    |                    |--------------------->|                   |
     |                    |                    |                      |                   |
     |                    |                    |                      |  Update RA        |
     |                    |                    |                      |  dates in modul   |
     |                    |                    |                      |------------------>|
     |                    |                    |                      |                   |
     |  Display updated   |                    |                      |                   |
     |  dates             |                    |                      |                   |
     |<------------------------------------ ---|                      |                   |
     |                    |                    |                      |                   |
```

---

### 2.5 Enter Daily Notes

```
+===========================================================================+
|            SEQUENCE DIAGRAM: UC09 - Enter Daily Notes                      |
+===========================================================================+

  Teacher            DailyNotesPage                        AppStateNotifier       AppState
     |                    |                                      |                   |
     |  Navigate to       |                                      |                   |
     |  /daily-notes      |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  ref.watch(appStateProvider)         |                   |
     |                    |------------------------------------->|                   |
     |                    |                                      |                   |
     |                    |  AppState (with moduls list)         |                   |
     |                    |<-------------------------------------|                   |
     |                    |                                      |                   |
     |  Display module    |                                      |                   |
     |  dropdown          |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
     |  Select module     |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |  Display RA        |                                      |                   |
     |  dropdown          |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
     |  Select RA         |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  Check RA dates                      |                   |
     |                    |----------+                           |                   |
     |                    |          |                           |                   |
     |                    |<---------+                           |                   |
     |                    |                                      |                   |
     |  alt [RA has no dates configured]                         |                   |
     |  +-----------------------------------------------------+  |                   |
     |  |                 |                                   |  |                   |
     |  |  Show message:  |                                   |  |                   |
     |  |  "Configure     |                                   |  |                   |
     |  |  dates first"   |                                   |  |                   |
     |  |<----------------|                                   |  |                   |
     |  +-----------------------------------------------------+  |                   |
     |                    |                                      |                   |
     |  alt [RA has dates configured]                            |                   |
     |  +-----------------------------------------------------+  |                   |
     |  |                 |                                   |  |                   |
     |  |                 |  Generate days list               |  |                   |
     |  |                 |  (startDate to endDate)           |  |                   |
     |  |                 |----------+                        |  |                   |
     |  |                 |          |                        |  |                   |
     |  |                 |<---------+                        |  |                   |
     |  |                 |                                   |  |                   |
     |  |  Display list   |                                   |  |                   |
     |  |  of days with   |                                   |  |                   |
     |  |  note fields    |                                   |  |                   |
     |  |<----------------|                                   |  |                   |
     |  |                 |                                   |  |                   |
     |  |                 |  scrollToToday()                  |  |                   |
     |  |                 |----------+                        |  |                   |
     |  |                 |          |                        |  |                   |
     |  |                 |<---------+                        |  |                   |
     |  +-----------------------------------------------------+  |                   |
     |                    |                                      |                   |
     |  Type notes in     |                                      |                   |
     |  text field        |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  setDailyNote(DailyNote(             |                   |
     |                    |    raId, modulId, date,              |                   |
     |                    |    notes, completed))                |                   |
     |                    |------------------------------------->|                   |
     |                    |                                      |                   |
     |                    |                                      |  Update/create    |
     |                    |                                      |  dailyNote        |
     |                    |                                      |------------------>|
     |                    |                                      |                   |
     |  Click "Pendent"/  |                                      |                   |
     |  "Fet" chip        |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  setDailyNote(DailyNote(             |                   |
     |                    |    ...completed: !prev))             |                   |
     |                    |------------------------------------->|                   |
     |                    |                                      |                   |
     |                    |                                      |  Toggle completed |
     |                    |                                      |  status           |
     |                    |                                      |------------------>|
     |                    |                                      |                   |
     |  Update chip       |                                      |                   |
     |  display           |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
```

---

### 2.6 Manage Academic Year

```
+===========================================================================+
|          SEQUENCE DIAGRAM: UC11 - Set Academic Year                        |
+===========================================================================+

  Teacher           ConfiguracioPage                       AppStateNotifier       AppState
     |                    |                                      |                   |
     |  Navigate to       |                                      |                   |
     |  /configuracio     |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  ref.watch(appStateProvider)         |                   |
     |                    |------------------------------------->|                   |
     |                    |                                      |                   |
     |  alt [No academic year exists]                            |                   |
     |  +-----------------------------------------------------+  |                   |
     |  |                 |                                   |  |                   |
     |  |  Display        |                                   |  |                   |
     |  |  "Crear curs"   |                                   |  |                   |
     |  |  button         |                                   |  |                   |
     |  |<----------------|                                   |  |                   |
     |  |                 |                                   |  |                   |
     |  |  Click "Crear   |                                   |  |                   |
     |  |  curs acadèmic" |                                   |  |                   |
     |  |---------------->|                                   |  |                   |
     |  |                 |                                   |  |                   |
     |  |                 |  showDialog()                     |  |                   |
     |  |                 |----------+                        |  |                   |
     |  |                 |          |                        |  |                   |
     |  |  Display form   |<---------+                        |  |                   |
     |  |  dialog         |                                   |  |                   |
     |  |<----------------|                                   |  |                   |
     |  |                 |                                   |  |                   |
     |  |  Fill:          |                                   |  |                   |
     |  |  - name         |                                   |  |                   |
     |  |  - startDate    |                                   |  |                   |
     |  |  - endDate      |                                   |  |                   |
     |  |---------------->|                                   |  |                   |
     |  |                 |                                   |  |                   |
     |  |  Click "Desar"  |                                   |  |                   |
     |  |---------------->|                                   |  |                   |
     |  |                 |                                   |  |                   |
     |  |                 |  setCurrentYear(AcademicYear)     |  |                   |
     |  |                 |------------------------------------->|                   |
     |  |                 |                                   |  |                   |
     |  |                 |                                   |  |  Set currentYear  |
     |  |                 |                                   |  |------------------>|
     |  +-----------------------------------------------------+  |                   |
     |                    |                                      |                   |
     |  Display academic  |                                      |                   |
     |  year details      |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |


+===========================================================================+
|      SEQUENCE DIAGRAM: UC12 - Manage Vacation Periods                      |
+===========================================================================+

  Teacher           ConfiguracioPage                       AppStateNotifier       AppState
     |                    |                                      |                   |
     |  Click "Afegir     |                                      |                   |
     |  període"          |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  showDialog()                        |                   |
     |                    |----------+                           |                   |
     |                    |          |                           |                   |
     |  Display vacation  |<---------+                           |                   |
     |  period form       |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
     |  Fill:             |                                      |                   |
     |  - name (Nadal)    |                                      |                   |
     |  - startDate       |                                      |                   |
     |  - endDate         |                                      |                   |
     |  - note (optional) |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |  Click "Afegir"    |                                      |                   |
     |------------------->|                                      |                   |
     |                    |                                      |                   |
     |                    |  addVacationPeriod(VacationPeriod)   |                   |
     |                    |------------------------------------->|                   |
     |                    |                                      |                   |
     |                    |                                      |  Add period to    |
     |                    |                                      |  currentYear      |
     |                    |                                      |  .vacationPeriods |
     |                    |                                      |------------------>|
     |                    |                                      |                   |
     |  Display updated   |                                      |                   |
     |  periods list      |                                      |                   |
     |<-------------------|                                      |                   |
     |                    |                                      |                   |
```

---

### 2.7 Manage Groups

```
+===========================================================================+
|             SEQUENCE DIAGRAM: UC14 - Create Group                          |
+===========================================================================+

  Teacher            GrupsListPage          GroupFormPage       AppStateNotifier       AppState
     |                    |                    |                      |                   |
     |  Navigate to       |                    |                      |                   |
     |  /grups            |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |                    |  ref.watch(appStateProvider)              |                   |
     |                    |-------------------------------------------->                  |
     |                    |                    |                      |                   |
     |  Display groups    |                    |                      |                   |
     |  list              |                    |                      |                   |
     |<-------------------|                    |                      |                   |
     |                    |                    |                      |                   |
     |  Click "Afegir     |                    |                      |                   |
     |  grup"             |                    |                      |                   |
     |------------------->|                    |                      |                   |
     |                    |                    |                      |                   |
     |                    |  Navigate to       |                      |                   |
     |                    |  /grups/new        |                      |                   |
     |                    |------------------->|                      |                   |
     |                    |                    |                      |                   |
     |  Display group     |                    |                      |                   |
     |  form              |                    |                      |                   |
     |<----------------------------------------|                      |                   |
     |                    |                    |                      |                   |
     |  Fill:             |                    |                      |                   |
     |  - name (DAW1-A)   |                    |                      |                   |
     |  - notes (optional)|                    |                      |                   |
     |---------------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |  Click "Desar"     |                    |                      |                   |
     |---------------------------------------->|                      |                   |
     |                    |                    |                      |                   |
     |                    |                    |  validate form       |                   |
     |                    |                    |----------+           |                   |
     |                    |                    |          |           |                   |
     |                    |                    |<---------+           |                   |
     |                    |                    |                      |                   |
     |                    |                    |  addGroup(Group)     |                   |
     |                    |                    |--------------------->|                   |
     |                    |                    |                      |                   |
     |                    |                    |                      |  Add group to     |
     |                    |                    |                      |  state.groups     |
     |                    |                    |                      |------------------>|
     |                    |                    |                      |                   |
     |                    |                    |  context.pop()       |                   |
     |                    |                    |--------------------->|                   |
     |                    |                    |                      |                   |
     |  Display updated   |                    |                      |                   |
     |  groups list       |                    |                      |                   |
     |<-------------------|                    |                      |                   |
     |                    |                    |                      |                   |
```

---

## 3. Use Case Descriptions

### UC01 - Import Curriculum Modules
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | Curriculum YAML file exists in assets |
| **Main Flow** | 1. Teacher navigates to Setup Curriculum page<br>2. System loads available cycles from YAML<br>3. Teacher selects cycles to use (Step 1)<br>4. Teacher selects modules to import (Step 2)<br>5. Teacher clicks "Importa"<br>6. System creates Modul entities with auto-generated RAs from UFs |
| **Postcondition** | Selected modules are added to state with RAs |

### UC02 - Create Module Manually
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | None |
| **Main Flow** | 1. Teacher navigates to Modules page<br>2. Teacher clicks FAB (+)<br>3. Teacher fills module form (code, name, hours, etc.)<br>4. Teacher clicks "Desar"<br>5. System validates and saves module |
| **Postcondition** | New module exists in state |

### UC05 - Add RA to Module
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | Module exists |
| **Main Flow** | 1. Teacher views module detail<br>2. Teacher clicks "Afegir RA"<br>3. Teacher fills RA form (number, code, title, hours)<br>4. Teacher clicks "Desar"<br>5. System adds RA to module |
| **Postcondition** | RA is added to the module's ras list |

### UC08 - Configure RA Dates
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | Module with at least one RA exists |
| **Main Flow** | 1. Teacher views module detail<br>2. Teacher clicks "Configurar dates"<br>3. Teacher clicks edit on an RA<br>4. Teacher sets start and end dates<br>5. Teacher clicks "Desar" |
| **Postcondition** | RA has startDate and endDate set |

### UC09 - Enter Daily Notes
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | RA exists with dates configured |
| **Main Flow** | 1. Teacher navigates to Daily Notes<br>2. Teacher selects module and RA<br>3. System displays days in RA date range<br>4. Teacher types notes for each day<br>5. System auto-saves on change |
| **Postcondition** | DailyNote entries exist for edited days |

### UC10 - Mark Session Complete
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | Daily note view is displayed |
| **Main Flow** | 1. Teacher clicks "Pendent"/"Fet" chip<br>2. System toggles completion status<br>3. System saves updated note |
| **Postcondition** | DailyNote.completed is toggled |

### UC11 - Set Academic Year
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | None |
| **Main Flow** | 1. Teacher navigates to Configuration<br>2. Teacher clicks "Crear curs acadèmic"<br>3. Teacher fills form (name, dates)<br>4. Teacher clicks "Desar" |
| **Postcondition** | currentYear is set in state |

### UC12 - Manage Vacation Periods
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | Academic year exists |
| **Main Flow** | 1. Teacher clicks "Afegir període"<br>2. Teacher fills vacation period form<br>3. Teacher clicks "Afegir"<br>4. System adds period to currentYear |
| **Postcondition** | Vacation period added to academic year |

### UC13 - Manage Recurring Holidays
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | None (12 Catalan holidays pre-loaded) |
| **Main Flow** | 1. Teacher views holidays list<br>2. Teacher toggles enable/disable switch<br>3. System saves updated holiday status |
| **Postcondition** | Holiday isEnabled status updated |

### UC14 - Create Group
| Field | Description |
|-------|-------------|
| **Actor** | Teacher |
| **Precondition** | None |
| **Main Flow** | 1. Teacher navigates to Groups<br>2. Teacher clicks "Afegir grup"<br>3. Teacher fills form (name, notes)<br>4. Teacher clicks "Desar" |
| **Postcondition** | New group exists in state |

---

## 4. Domain Model (Class Diagram)

```
+===========================================================================+
|                         DOMAIN MODEL                                       |
+===========================================================================+

+-------------------+           +-------------------+
|    AcademicYear   |           |  VacationPeriod   |
+-------------------+           +-------------------+
| - id: String      |    1..*   | - id: String      |
| - name: String    |<>---------| - name: String    |
| - startDate: Date |           | - startDate: Date |
| - endDate: Date   |           | - endDate: Date   |
| - isActive: bool  |           | - note: String?   |
+-------------------+           +-------------------+


+-------------------+
| RecurringHoliday  |
+-------------------+
| - id: String      |
| - name: String    |
| - month: int      |
| - day: int        |
| - isEnabled: bool |
+-------------------+


+-------------------+           +-------------------+           +-------------------+
|      Modul        |           |        RA         |           | CriteriAvaluacio  |
+-------------------+           +-------------------+           +-------------------+
| - id: String      |    1..*   | - id: String      |    0..*   | - id: String      |
| - code: String    |<>---------| - number: int     |<>---------| - code: String    |
| - name: String    |           | - code: String    |           | - description:    |
| - description:    |           | - title: String   |           |     String        |
|     String?       |           | - description:    |           | - order: int      |
| - totalHours: int |           |     String?       |           +-------------------+
| - objectives:     |           | - durationHours:  |
|     String?       |           |     int           |
| - officialRef:    |           | - order: int      |
|     String?       |           | - startDate: Date?|
| - cicleCode:      |           | - endDate: Date?  |
|     String?       |           +-------------------+
+-------------------+                    |
                                         |
                                         | raId
                                         |
                                         v
+-------------------+           +-------------------+
|      Group        |           |    DailyNote      |
+-------------------+           +-------------------+
| - id: String      |           | - id: String      |
| - name: String    |           | - raId: String    |
| - notes: String?  |           | - modulId: String |
| - academicYearId: |           | - date: Date      |
|     String?       |           | - notes: String   |
+-------------------+           | - completed: bool |
                                +-------------------+


+===========================================================================+
|                          STATE CONTAINER                                   |
+===========================================================================+

+---------------------------+
|         AppState          |
+---------------------------+
| - currentYear:            |
|     AcademicYear?         |
| - recurringHolidays:      |
|     List<RecurringHoliday>|
| - groups: List<Group>     |
| - moduls: List<Modul>     |
| - selectedCicleIds:       |
|     List<String>          |
| - dailyNotes:             |
|     List<DailyNote>       |
+---------------------------+
```

---

## 5. Navigation Structure

```
+===========================================================================+
|                       NAVIGATION MAP                                       |
+===========================================================================+

                              +-------------+
                              |   AppShell  |
                              | (Drawer Nav)|
                              +------+------+
                                     |
         +-------+-------+-------+---+---+-------+-------+-------+
         |       |       |       |       |       |       |       |
         v       v       v       v       v       v       v       v
    +----+--+ +--+---+ +-+----+ +---+--+ +--+---+ +--+---+ +--+---+
    |   /   | |/calen| |/moduls| |/grups| |/tasq| |/info| |/arxi|
    |Dashbrd| | dar  | | List | | List | | ues | | rmes| |  u  |
    +-------+ +------+ +---+---+ +--+---+ +-----+ +-----+ +-----+
                           |        |
              +------+-----+        +-------+
              |      |                      |
              v      v                      v
         +----+--+ +-+------+          +----+---+
         |/moduls| |/moduls/|          |/grups/ |
         |  /:id | |edit/:id|          | new    |
         |Detail | | Form   |          | Form   |
         +---+---+ +--------+          +----+---+
             |                              |
    +--------+--------+                     v
    |        |        |                +----+---+
    v        v        v                |/grups/ |
+---+----+ +-+------+ +---+----+       |edit/:id|
|/moduls/| |/moduls/| |/moduls/|       | Form   |
|:id/ra/ | |:id/ra/ | |:id/    |       +--------+
| new    | |edit/:ra| |ra-confi|
| Form   | | Form   | | g      |
+--------+ +--------+ +--------+


Other routes:
+----------------+     +-------------------+
| /configuracio  |     | /setup-curriculum |
| Config Page    |     | Curriculum Import |
+----------------+     +-------------------+

+----------------+
| /daily-notes   |
| Daily Notes    |
+----------------+
```

---

**End of Document**
