# Implementation Plan Document - v0.0.3 Local Database

## Goal
1. Create Docker-based MongoDB setup for local development on Linux
2. Design MongoDB schema based on application data models
3. Use `.env` files for sensitive credentials (not committed to git)

---

## Part 1: MongoDB Docker Setup

### Approach: Docker Container

**Rationale:**
- Isolated environment, no system pollution
- Reproducible setup across machines
- Easy cleanup and version switching
- Data persisted via Docker volumes
- No sudo required for daily operations
- Credentials stored in `.env` files (git-ignored)

---

### Environment Files

#### Template File (`docker/.env.example`) - COMMITTED to git

```bash
# MongoDB Docker Environment Configuration
# Copy this file to .env and customize values

# MongoDB Admin User (for initial setup)
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=change_me_admin_password

# MongoDB Application User (used by Flutter app)
MONGO_APP_USER=cam_user
MONGO_APP_PASSWORD=change_me_app_password
MONGO_APP_DATABASE=class_activity_manager

# Mongo Express Web UI credentials
MONGO_EXPRESS_USER=admin
MONGO_EXPRESS_PASSWORD=change_me_express_password

# Ports (change if conflicts)
MONGO_PORT=27017
MONGO_EXPRESS_PORT=8081
```

#### Local Environment File (`docker/.env`) - NOT committed (git-ignored)

Created by copying `.env.example` and setting real passwords.

---

### .gitignore Additions

```gitignore
# MongoDB Docker environment (contains credentials)
docker/.env
docker/.env.local
docker/.env.*.local

# MongoDB data (if using bind mount instead of volume)
docker/data/

# Flutter app environment
lib/.env
lib/.env.local
```

---

## Part 2: MongoDB Schema Design

### Design Principles

1. **Embed** data that is:
   - Always accessed together
   - Has 1:few relationship
   - Doesn't change independently

2. **Reference** data that is:
   - Accessed independently
   - Has 1:many or many:many relationship
   - Changes frequently

### Collections Overview

```
class_activity_manager/
├── academic_years      (embed: vacationPeriods)
├── recurring_holidays  (standalone)
├── groups              (reference: moduleIds, academicYearId)
├── moduls              (embed: ras → criterisAvaluacio)
├── daily_notes         (reference: groupId, modulId, raId)
└── app_settings        (user preferences, selectedCicleIds)
```

---

### Collection: `academic_years`

```javascript
{
  _id: ObjectId,
  name: "2024-2025",                    // String, required
  startDate: ISODate("2024-09-09"),     // Date, required
  endDate: ISODate("2025-06-20"),       // Date, required
  isActive: true,                        // Boolean, default false
  vacationPeriods: [                     // Embedded array
    {
      _id: ObjectId,
      name: "Nadal",
      startDate: ISODate("2024-12-21"),
      endDate: ISODate("2025-01-07"),
      note: "Vacances de Nadal"          // Optional
    }
  ],
  createdAt: ISODate,
  updatedAt: ISODate
}

// Indexes:
db.academic_years.createIndex({ isActive: 1 })
db.academic_years.createIndex({ startDate: 1, endDate: 1 })
```

---

### Collection: `recurring_holidays`

```javascript
{
  _id: ObjectId,
  name: "Nadal",                // String, required
  month: 12,                    // Int (1-12), required
  day: 25,                      // Int (1-31), required
  isEnabled: true,              // Boolean, default true
  createdAt: ISODate,
  updatedAt: ISODate
}

// Indexes:
db.recurring_holidays.createIndex({ month: 1, day: 1 })
db.recurring_holidays.createIndex({ isEnabled: 1 })

// Default data (Catalan holidays):
// Cap d'Any (1/1), Reis (6/1), Dia del Treball (1/5), Sant Joan (24/6),
// L'Assumpció (15/8), Diada (11/9), Festa Nacional (12/10), Tots Sants (1/11),
// Constitució (6/12), Immaculada (8/12), Nadal (25/12), Sant Esteve (26/12)
```

---

### Collection: `groups`

```javascript
{
  _id: ObjectId,
  name: "DAW1-A",               // String, required, unique per academicYear
  notes: "Grup de matí",        // String, optional
  academicYearId: ObjectId,     // Reference to academic_years, optional
  moduleIds: [ObjectId],        // Array of references to moduls
  createdAt: ISODate,
  updatedAt: ISODate
}

// Indexes:
db.groups.createIndex({ academicYearId: 1 })
db.groups.createIndex({ moduleIds: 1 })  // Multikey index
db.groups.createIndex({ name: 1, academicYearId: 1 }, { unique: true })
```

---

### Collection: `moduls`

```javascript
{
  _id: ObjectId,
  code: "MP06",                          // String, required, unique
  name: "Desenvolupament web en entorn client",
  description: "...",                    // Optional
  totalHours: 132,                       // Int, required
  objectives: ["Obj1", "Obj2"],          // Array of strings
  officialReference: "RD...",            // Optional
  cicleCodes: ["ICC0", "ICB0"],          // Array of cycle codes (DAM, DAW)
  ras: [                                 // Embedded array of RAs
    {
      _id: ObjectId,
      number: 1,
      code: "RA1",
      title: "Selecciona les arquitectures...",
      description: "...",                // Optional
      durationHours: 22,
      order: 0,
      startDate: ISODate,                // Optional, set by teacher
      endDate: ISODate,                  // Optional, set by teacher
      criterisAvaluacio: [               // Embedded within RA
        {
          _id: ObjectId,
          code: "a",
          description: "S'han caracteritzat...",
          order: 0
        }
      ]
    }
  ],
  createdAt: ISODate,
  updatedAt: ISODate
}

// Indexes:
db.moduls.createIndex({ code: 1 }, { unique: true })
db.moduls.createIndex({ cicleCodes: 1 })  // Multikey index
db.moduls.createIndex({ "ras._id": 1 })   // For RA lookups
```

---

### Collection: `daily_notes`

```javascript
{
  _id: ObjectId,
  groupId: ObjectId,            // Reference to groups, required
  modulId: ObjectId,            // Reference to moduls, required
  raId: ObjectId,               // Reference to RA (embedded in modul), required
  date: ISODate,                // Date only (no time), required
  plannedContent: "...",        // String, optional
  actualContent: "...",         // String, optional
  notes: "...",                 // String, optional (observations)
  completed: false,             // Boolean, default false
  createdAt: ISODate,
  updatedAt: ISODate
}

// Indexes (critical for performance):
db.daily_notes.createIndex(
  { groupId: 1, raId: 1, date: 1 },
  { unique: true }  // Prevents duplicates
)
db.daily_notes.createIndex({ raId: 1 })
db.daily_notes.createIndex({ modulId: 1 })
db.daily_notes.createIndex({ date: 1 })
db.daily_notes.createIndex({ groupId: 1, modulId: 1 })  // For filtering
```

---

### Collection: `app_settings`

```javascript
{
  _id: "user_settings",         // Single document pattern
  selectedCicleIds: ["ICC0"],   // User's selected cycles for import
  lastAcademicYearId: ObjectId, // Last used academic year
  theme: "light",               // UI preferences
  updatedAt: ISODate
}
```

---

## Data Relationships Diagram

```
academic_years ←─────────────────┐
     │                           │
     │ (embed)                   │ (ref: academicYearId)
     ▼                           │
vacation_periods                 │
                                 │
recurring_holidays (standalone)  │
                                 │
groups ──────────────────────────┘
     │
     │ (ref: moduleIds)
     ▼
moduls
     │
     │ (embed)
     ▼
ras
     │
     │ (embed)
     ▼
criteris_avaluacio

daily_notes
     │
     ├── (ref) → groupId → groups
     ├── (ref) → modulId → moduls
     └── (ref) → raId → moduls.ras[]
```

---

## Files to Create

| File | Purpose | Git |
|------|---------|-----|
| `docker/.env.example` | Template with placeholder credentials | ✅ Committed |
| `docker/.env` | Real credentials (copied from example) | ❌ Ignored |
| `docker/docker-compose.yml` | Docker Compose config (uses .env vars) | ✅ Committed |
| `docker/init-mongo.js` | Initial user creation (reads env vars) | ✅ Committed |
| `scripts/setup-mongodb.sh` | One-time setup script | ✅ Committed |
| `scripts/mongo-start.sh` | Start MongoDB container | ✅ Committed |
| `scripts/mongo-stop.sh` | Stop MongoDB container | ✅ Committed |
| `scripts/mongo-shell.sh` | Open mongosh in container | ✅ Committed |
| `scripts/mongo-logs.sh` | Tail container logs | ✅ Committed |
| `scripts/init-db.js` | Database schema and indexes init | ✅ Committed |
| `.gitignore` | Updated with docker/.env entries | ✅ Committed |

---

## Verification Steps

1. Run `chmod +x scripts/*.sh` - make scripts executable
2. Run `./scripts/setup-mongodb.sh` - first run creates `.env` from template
3. Edit `docker/.env` - set secure passwords
4. Run `./scripts/setup-mongodb.sh` - start Docker containers
5. Open `http://localhost:8081` - verify Mongo Express UI works (credentials from .env)
6. Run `./scripts/mongo-shell.sh` - verify shell connection
7. In shell: `show collections` - verify empty database
8. Run `./scripts/mongo-shell.sh < scripts/init-db.js` - create schema
9. In shell: `show collections` - verify collections created
10. In shell: `db.recurring_holidays.find()` - verify default data
11. Verify `docker/.env` is NOT tracked: `git status` should not show it

---

## Flutter Integration Notes (Future)

For Flutter integration, will need:
- `mongo_dart` package for direct MongoDB connection (desktop app)
- Or REST API layer if web/mobile needed
- Repository pattern in `lib/data/repositories/`
- Convert between Dart models and MongoDB documents

**Environment Configuration for Flutter:**

Create `lib/.env.example` (committed) and `lib/.env` (ignored):

```bash
# lib/.env.example - Template for Flutter app
MONGO_URI=mongodb://user:password@localhost:27017/class_activity_manager
```

Use `flutter_dotenv` package to load:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: "lib/.env");
  final mongoUri = dotenv.env['MONGO_URI']!;
  // ... connect to MongoDB
}
```
