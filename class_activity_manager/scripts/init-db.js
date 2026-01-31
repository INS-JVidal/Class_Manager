// MongoDB Schema Initialization Script
// Run with: ./scripts/mongo-shell.sh < scripts/init-db.js
// Or: docker exec -i cam_mongodb mongosh -u cam_user -p <password> class_activity_manager < scripts/init-db.js

print("=== Initializing Class Activity Manager Database ===");

// Create collections with validation
print("Creating collections with validation...");

db.createCollection("academic_years", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "startDate", "endDate"],
      properties: {
        name: { bsonType: "string", description: "Academic year name (e.g., 2024-2025)" },
        startDate: { bsonType: "date", description: "Start date of academic year" },
        endDate: { bsonType: "date", description: "End date of academic year" },
        isActive: { bsonType: "bool", description: "Whether this is the active academic year" },
        vacationPeriods: {
          bsonType: "array",
          description: "Embedded vacation periods",
          items: {
            bsonType: "object",
            required: ["name", "startDate", "endDate"],
            properties: {
              name: { bsonType: "string" },
              startDate: { bsonType: "date" },
              endDate: { bsonType: "date" },
              note: { bsonType: "string" }
            }
          }
        }
      }
    }
  }
});

db.createCollection("recurring_holidays", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "month", "day"],
      properties: {
        name: { bsonType: "string", description: "Holiday name" },
        month: { bsonType: "int", minimum: 1, maximum: 12, description: "Month (1-12)" },
        day: { bsonType: "int", minimum: 1, maximum: 31, description: "Day of month (1-31)" },
        isEnabled: { bsonType: "bool", description: "Whether this holiday is active" }
      }
    }
  }
});

db.createCollection("groups", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name"],
      properties: {
        name: { bsonType: "string", description: "Group name (e.g., DAW1-A)" },
        notes: { bsonType: "string", description: "Optional notes" },
        academicYearId: { bsonType: "objectId", description: "Reference to academic_years" },
        moduleIds: { bsonType: "array", items: { bsonType: "objectId" }, description: "References to moduls" }
      }
    }
  }
});

db.createCollection("moduls", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["code", "name", "totalHours"],
      properties: {
        code: { bsonType: "string", description: "Module code (e.g., MP06)" },
        name: { bsonType: "string", description: "Module name" },
        description: { bsonType: "string" },
        totalHours: { bsonType: "int", description: "Total hours for the module" },
        objectives: { bsonType: "array", items: { bsonType: "string" } },
        officialReference: { bsonType: "string" },
        cicleCodes: { bsonType: "array", items: { bsonType: "string" }, description: "Cycle codes (DAM, DAW)" },
        ras: {
          bsonType: "array",
          description: "Embedded RAs (Resultats d'Aprenentatge)",
          items: {
            bsonType: "object",
            required: ["number", "code", "title"],
            properties: {
              number: { bsonType: "int" },
              code: { bsonType: "string" },
              title: { bsonType: "string" },
              description: { bsonType: "string" },
              durationHours: { bsonType: "int" },
              order: { bsonType: "int" },
              startDate: { bsonType: "date" },
              endDate: { bsonType: "date" },
              criterisAvaluacio: {
                bsonType: "array",
                items: {
                  bsonType: "object",
                  required: ["code", "description"],
                  properties: {
                    code: { bsonType: "string" },
                    description: { bsonType: "string" },
                    order: { bsonType: "int" }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
});

db.createCollection("daily_notes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["groupId", "modulId", "raId", "date"],
      properties: {
        groupId: { bsonType: "objectId", description: "Reference to groups" },
        modulId: { bsonType: "objectId", description: "Reference to moduls" },
        raId: { bsonType: "objectId", description: "Reference to RA within modul" },
        date: { bsonType: "date", description: "Date of the note" },
        plannedContent: { bsonType: "string", description: "Planned content for the session" },
        actualContent: { bsonType: "string", description: "Actual content covered" },
        notes: { bsonType: "string", description: "Additional observations" },
        completed: { bsonType: "bool", description: "Whether session was completed" }
      }
    }
  }
});

db.createCollection("app_settings");

print("Collections created.");

// Create indexes
print("Creating indexes...");

db.academic_years.createIndex({ isActive: 1 });
db.academic_years.createIndex({ startDate: 1, endDate: 1 });

db.recurring_holidays.createIndex({ month: 1, day: 1 });
db.recurring_holidays.createIndex({ isEnabled: 1 });

db.groups.createIndex({ academicYearId: 1 });
db.groups.createIndex({ moduleIds: 1 });
db.groups.createIndex({ name: 1, academicYearId: 1 }, { unique: true });

db.moduls.createIndex({ code: 1 }, { unique: true });
db.moduls.createIndex({ cicleCodes: 1 });
db.moduls.createIndex({ "ras._id": 1 });

db.daily_notes.createIndex({ groupId: 1, raId: 1, date: 1 }, { unique: true });
db.daily_notes.createIndex({ raId: 1 });
db.daily_notes.createIndex({ modulId: 1 });
db.daily_notes.createIndex({ date: 1 });
db.daily_notes.createIndex({ groupId: 1, modulId: 1 });

print("Indexes created.");

// Insert default recurring holidays (Catalan)
print("Inserting default Catalan holidays...");

db.recurring_holidays.insertMany([
  { name: "Cap d'Any", month: 1, day: 1, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Reis", month: 1, day: 6, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Dia del Treball", month: 5, day: 1, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Sant Joan", month: 6, day: 24, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "L'Assumpció", month: 8, day: 15, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Diada Nacional de Catalunya", month: 9, day: 11, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Festa Nacional d'Espanya", month: 10, day: 12, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Tots Sants", month: 11, day: 1, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Dia de la Constitució", month: 12, day: 6, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "La Immaculada", month: 12, day: 8, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Nadal", month: 12, day: 25, isEnabled: true, createdAt: new Date(), updatedAt: new Date() },
  { name: "Sant Esteve", month: 12, day: 26, isEnabled: true, createdAt: new Date(), updatedAt: new Date() }
]);

print("Default holidays inserted.");

// Initialize app_settings
print("Initializing app settings...");

db.app_settings.insertOne({
  _id: "user_settings",
  selectedCicleIds: [],
  theme: "light",
  createdAt: new Date(),
  updatedAt: new Date()
});

print("App settings initialized.");

print("");
print("=== Database initialization complete! ===");
print("");
print("Collections created:");
db.getCollectionNames().forEach(function(c) { print("  - " + c); });
print("");
print("Holiday count: " + db.recurring_holidays.countDocuments());
