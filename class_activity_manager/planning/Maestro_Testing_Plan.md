# Maestro Testing Integration Plan

**Status:** For later use. Current app is Linux desktop only.

**Context:** Maestro is a promising UI testing tool. This plan documents integration options and test scenarios for when Maestro becomes applicable (web or mobile targets).

---

## 1. Limitation: Maestro and Flutter Desktop

**Maestro cannot test Flutter Desktop (Linux) apps.** Per [Maestro Flutter docs](https://docs.maestro.dev/platform-support/flutter):

> "Maestro cannot be used to test Flutter Desktop apps yet."

**Implication:** With a desktop-only app, Maestro cannot be used directly today.

**Paths when Maestro becomes applicable:**

| Path | When | Description |
|------|------|-------------|
| Flutter Web | Enable web target | Run app in browser; Maestro tests Web (Desktop Browser). Same codebase. |
| Android/iOS | When platforms added per PRD | Maestro supports Flutter on mobile. |

---

## 2. Alternative for Linux Desktop Now

For automated UI testing on Linux desktop today, use **Flutter integration_test**:

- Add `integration_test/` folder with Dart tests.
- Run: `xvfb-run flutter test integration_test -d linux`
- Uses `flutter_test` APIs (Finder, pumpWidget, tap, etc.).
- No Maestro; different syntax and tooling.

---

## 3. Pre-work: Semantics Identifiers

When Maestro (or another accessibility-based tool) is used, the app should expose stable selectors. Add `Semantics(identifier: '...')` to key widgets:

| Screen / Action | Identifier | Purpose |
|-----------------|------------|---------|
| Nav items | `nav_dashboard`, `nav_moduls`, `nav_grups`, `nav_configuracio`, `nav_daily_notes` | Reliable nav taps |
| Configuració | `btn_create_academic_year`, `btn_add_vacation`, `btn_add_holiday` | Create flows |
| Mòduls | `btn_add_modul`, `btn_configurar_dates`, `btn_add_ra` | Module/RA flows |
| Setup curriculum | `checkbox_cicle_ICC0`, `btn_import_modules` | Curriculum import |
| Daily notes | `dropdown_modul`, `dropdown_ra`, `input_notes` | Notes flow |

---

## 4. Test Scenarios (Reference)

### Navigation and Shell

| ID | Scenario | Steps | Assertion |
|----|----------|-------|-----------|
| N1 | Navigate main sections | Tap Dashboard, Mòduls, Grups, Configuració, Notes diàries | Each view loads |
| N2 | Drill-down and back | Mòduls -> Module detail -> Back | Returns to list |

### Configuració

| ID | Scenario | Steps | Assertion |
|----|----------|-------|-----------|
| C1 | Create academic year | Configuració -> Enter name, dates -> Crea curs acadèmic | Year appears |
| C2 | Add vacation period | Configuració -> Afegir període -> Fill -> Desa | Period in list |
| C3 | Add recurring holiday | Configuració -> Afegir festiu -> Fill -> Desa | Holiday in list |
| C4 | Toggle recurring holiday | Configuració -> Toggle switch | State persists |

### Mòduls and Curriculum

| ID | Scenario | Steps | Assertion |
|----|----------|-------|-----------|
| M1 | Import modules | Configuració currículum -> Select cicle -> Select modules -> Importa | Modules in Mòduls list |
| M2 | Open module detail | Mòduls -> Tap module | Detail shows RAs |
| M3 | Configure RA dates | Module detail -> Configurar dates -> Edit RA -> Desa | Dates saved |

### Grups

| ID | Scenario | Steps | Assertion |
|----|----------|-------|-----------|
| G1 | Create group | Grups -> Afegir grup -> Name, notes -> Desa | Group in list |
| G2 | Edit group | Grups -> Tap group -> Edit -> Desa | Updated in list |

### Daily Notes

| ID | Scenario | Steps | Assertion |
|----|----------|-------|-----------|
| D1 | View daily notes | Notes diàries -> Select Modul -> Select RA | Day list or empty |
| D2 | Add note | Notes diàries -> Select Modul/RA -> Day -> Enter notes | Note visible |
| D3 | Mark day done | Notes diàries -> Tap "Pendent" chip | Chip shows "Fet" |

### Placeholders

| ID | Scenario | Steps | Assertion |
|----|----------|-------|-----------|
| P1 | Placeholder views | Tap Calendar, Tasques, Informes, Arxiu | "En desenvolupament" |

---

## 5. Maestro Setup (When Applicable)

### Install

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

### Project Structure

```
maestro/
├── config.yaml
├── flows/
│   ├── 01_navigation.yaml
│   ├── 02_configuracio_create_year.yaml
│   ├── 03_configuracio_holidays.yaml
│   ├── 04_moduls_import_curriculum.yaml
│   ├── 05_moduls_ra_config.yaml
│   ├── 06_grups_crud.yaml
│   ├── 07_daily_notes.yaml
│   └── 08_smoke.yaml
```

### Run

- **Web:** Build `flutter build web`, serve, then `maestro test maestro/flows/` with app URL.
- **Mobile:** `maestro test maestro/flows/` with device/emulator.

---

## 6. Summary

| Question | Answer |
|----------|--------|
| Maestro for Linux desktop? | No — not supported. |
| For later use? | Yes — when web or mobile targets exist. |
| Desktop testing now? | Use Flutter `integration_test` on Linux. |
| Pre-work? | Add Semantics identifiers for future Maestro use. |
