# Review-Consistency Skill — User Guide

This guide explains the **review-consistency** Cursor skill: what it does and how to use it to check Flutter/Dart code for consistency with Class Activity Manager project patterns.

## Table of Contents

- [What It Does](#what-it-does)
- [Where the Skill Lives](#where-the-skill-lives)
- [How to Use It](#how-to-use-it)
- [What It Checks](#what-it-checks)
- [Understanding the Output](#understanding-the-output)
- [When to Use It](#when-to-use-it)
- [Related Documentation](#related-documentation)

---

## What It Does

The **review-consistency** skill instructs the Cursor AI to review your code against the project’s established patterns. It does **not** run automatically; you trigger it by asking for a consistency review. The AI then:

1. Reads the file(s), diff, or folder you specify
2. Checks the code against a fixed checklist (naming, Riverpod usage, error handling, audit logging, widgets, forms, repositories, models, file structure)
3. Reports findings in a standard format with file, line, category, issue, and expected pattern

It helps keep new and changed code aligned with existing conventions (e.g. ConsumerWidget vs StatelessWidget, audit log phases, import order, GoRouter navigation).

---

## Where the Skill Lives

The skill is a **project-scoped** Cursor skill:

- **Path:** `.cursor/skills/review-consistency/SKILL.md`
- **Scope:** Only this repository; anyone who clones the project and uses Cursor can use it.

The full checklist and output format are defined in that `SKILL.md`. This user guide is a human-oriented summary; the skill file is what the AI follows.

---

## How to Use It

### 1. Open Cursor in this project

Make sure your workspace is the Class Activity Manager project root (where `.cursor/skills/` exists).

### 2. Ask for a consistency review

In the Cursor chat, ask the AI to review code for consistency. Be specific about **what** to review:

**Examples of prompts:**

- *“Review `lib/presentation/pages/daily_notes_page.dart` for consistency with project patterns.”*
- *“Check the code in `lib/state/app_state.dart` for consistency.”*
- *“Run a consistency review on the changes in my last commit.”*
- *“Review the `lib/data/repositories/` folder for consistency.”*

You can mention the skill by name if you want:

- *“Use the review-consistency skill on `lib/presentation/pages/configuracio_page.dart`.”*

### 3. Use the findings

The AI will respond with a list of findings in the format below. Use the file and line to open the code and apply the suggested pattern.

---

## What It Checks

The skill checks ten categories. Summary:

| Category | What it checks |
|----------|----------------|
| **naming** | File names (snake_case), classes (PascalCase), pages (*Page), form pages (*FormPage), repositories (Caching*Repository), cache schemas (*_cache.dart, *Cache) |
| **state** | ConsumerWidget for read-only views, ConsumerStatefulWidget for forms, ref.watch/ref.read usage, no notifier calls inside build() |
| **error-handling** | Try-catch around async work, audit log on failure, rethrow (no swallowing), fallback to local cache when remote fails |
| **audit** | traceId, phases (started → action → completed/failed), operation name (EntityType.action), payload with IDs, failed phase in catch |
| **imports** | Order: dart → flutter → packages → relative; blank line between groups |
| **widget** | ConsumerWidget for list/detail, ConsumerStatefulWidget for forms, _*PageState, post-frame callback for async init, dispose() for controllers |
| **form** | showConfirmDialog for confirmations, destructive styling for delete, notifier for submit, context.go()/context.pop(), notifier.nextId() for new IDs |
| **repository** | Extend BaseCachingRepository, implement entityType, collection, toCache, toEntity, toJson, getId; use LocalDatasource and SyncQueue |
| **model** | Immutable, copyWith(), toJson()/fromJson(), UUIDs for IDs, no mutable state |
| **structure** | Pages in presentation/pages, widgets in presentation/widgets, models in models/, repositories in data/repositories/, services in data/services/, barrel exports where used |

---

## Understanding the Output

Each finding is one line:

```
file:line | category | issue | expected pattern
```

**Example:**

```
lib/presentation/pages/new_page.dart:15 | state | Using StatefulWidget instead of ConsumerStatefulWidget | Use ConsumerStatefulWidget for forms with Riverpod access
```

- **file:line** — Where to look (file path and line number).
- **category** — One of: `naming`, `state`, `error-handling`, `audit`, `imports`, `widget`, `form`, `repository`, `model`, `structure`.
- **issue** — Short description of what’s wrong.
- **expected pattern** — What to do instead.

If there are no issues in a category, the AI omits that category from the report. You can filter or group findings by `category` if you process the output (e.g. fix all `imports` first).

---

## When to Use It

- **Before or after a PR:** Review the changed files for consistency.
- **After adding a new page or feature:** Run it on the new files and touched state/repos.
- **When refactoring:** Check that refactored code still follows the checklist.
- **Onboarding:** Use the checklist and output as a reference for project conventions.

It complements static analysis: `flutter analyze` and `dart format` catch syntax and style; this skill focuses on **project-specific** patterns (Riverpod, audit logging, structure).

---

## Related Documentation

- **Skill definition:** `.cursor/skills/review-consistency/SKILL.md`
- **Other code quality tools:** [code-quality-tools.md](code-quality-tools.md) (jscpd, Flutter analyzer, Dart format, lints)
- **Architecture and state:** `lib/state/app_state.dart`, `lib/state/providers.dart`
- **Audit logging:** `lib/core/audit/audit_logger.dart`
