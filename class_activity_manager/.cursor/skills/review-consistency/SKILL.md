---
name: review-consistency
description: Review Flutter/Dart code for consistency with project patterns including naming conventions, Riverpod state management, error handling, audit logging, widget patterns, and file structure. Use when reviewing code changes, PRs, or when the user asks to check code consistency.
---

# Review Consistency (Flutter / Class Activity Manager)

Reviews code for consistency with established project patterns. Apply to files, diffs, or folders when the user requests a consistency check or code review.

## Instructions

1. Read the target file(s), diff, or folder.
2. Check each category in the checklist below against the code.
3. Report findings in the output format. Omit categories with no issues.
4. Cite file and line (or method name) for each finding.

## Checklist

### 1. Naming Conventions

- [ ] **Files**: snake_case (e.g. `daily_note.dart`, `caching_modul_repository.dart`)
- [ ] **Classes**: PascalCase (e.g. `AppState`, `GrupsListPage`)
- [ ] **Variables and methods**: camelCase (e.g. `currentYear`, `setCurrentYear()`)
- [ ] **Private members**: `_` prefix (e.g. `_db`, `_ensureRepos()`)
- [ ] **Pages**: `*Page` suffix (e.g. `DashboardPage`, `ModulsListPage`)
- [ ] **Form pages**: `*FormPage` suffix (e.g. `GroupFormPage`)
- [ ] **Repositories**: `Caching*Repository` pattern (e.g. `CachingGroupRepository`)
- [ ] **Cache schemas**: `*_cache.dart` and `*Cache` class (e.g. `modul_cache.dart`, `ModulCache`)

### 2. State Management (Riverpod)

- [ ] **Read-only views**: Use `ConsumerWidget`, not plain `StatelessWidget`, when reading `appStateProvider`
- [ ] **Forms / local state**: Use `ConsumerStatefulWidget` when the widget needs Riverpod and local state
- [ ] **Read state**: `ref.watch(appStateProvider)` for reactive reads
- [ ] **Mutate state**: `ref.read(appStateProvider.notifier).methodName()` (never in `build()`)
- [ ] **No notifier calls in build**: Do not call notifier methods inside `build()`; use callbacks (e.g. `onPressed`)

### 3. Error Handling

- [ ] **Try-catch**: Async operations that can fail are wrapped in try-catch
- [ ] **Audit on failure**: Catch blocks log with audit logger before rethrowing
- [ ] **Rethrow**: Do not swallow exceptions; rethrow after logging
- [ ] **Fallback**: When remote fails, fall back to local cache where applicable

### 4. Audit Logging Pattern

- [ ] **Trace ID**: Generate `final traceId = _uuid.v4();` for operations that emit multiple log events
- [ ] **Phases**: Log `started` at entry, optional `action` for steps, then `completed` or `failed`
- [ ] **Operation name**: Use `'EntityType.action'` (e.g. `'DailyNote.save'`, `'AppState.loadFromDatabase'`)
- [ ] **Payload**: Include relevant IDs and step info (e.g. `{'groupId': id}`, `{'step': 'pullFromRemote'}`)
- [ ] **Failed phase**: In catch block, log `'failed'` with `{'error': e.toString()}` and same `traceId`

### 5. Import Ordering

- [ ] **Group 1**: `dart:*` (SDK)
- [ ] **Group 2**: `package:flutter/*`
- [ ] **Group 3**: `package:*` (third-party)
- [ ] **Group 4**: Relative imports (`../` or `../../`)
- [ ] **Blank line** between groups

### 6. Widget Patterns

- [ ] **List/detail pages**: Extend `ConsumerWidget`
- [ ] **Form pages**: Extend `ConsumerStatefulWidget` with private state class `_*PageState`
- [ ] **Async init**: Use `WidgetsBinding.instance.addPostFrameCallback` for one-off async work after first frame
- [ ] **Dispose**: Override `dispose()` and dispose `TextEditingController` and other resources

### 7. Form and Dialog Patterns

- [ ] **Confirmations**: Use `showConfirmDialog()` (or project equivalent) for delete/confirm dialogs
- [ ] **Destructive actions**: Use error/destructive color scheme for delete buttons
- [ ] **Form submit**: Call `ref.read(appStateProvider.notifier).methodName()` from callbacks
- [ ] **Navigation**: Use `context.go()` or `context.pop()`; do not mix with deprecated `Navigator.push`
- [ ] **New entity IDs**: Use `notifier.nextId()` for new entity IDs

### 8. Repository Pattern

- [ ] **Base class**: Caching repos extend `BaseCachingRepository<TEntity, TCache>`
- [ ] **Required members**: Implement `entityType`, `collection`, `toCache()`, `toEntity()`, `toJson()`, `getId()`
- [ ] **Dependencies**: Use `LocalDatasource` and `SyncQueue` as provided by the project

### 9. Model Pattern

- [ ] **Immutability**: Models are immutable; use `copyWith()` for updates
- [ ] **JSON**: Provide `toJson()` and `fromJson()` (or factory) for serialization
- [ ] **IDs**: Use UUIDs for entity IDs
- [ ] **No mutable state**: No public setters or mutable collections exposed

### 10. File Structure

- [ ] **Pages**: In `lib/presentation/pages/`
- [ ] **Reusable widgets**: In `lib/presentation/widgets/`
- [ ] **Domain models**: In `lib/models/`
- [ ] **Repositories**: In `lib/data/repositories/`
- [ ] **Services**: In `lib/data/services/`
- [ ] **Barrel exports**: Use project barrel files (e.g. `models.dart`, `widgets.dart`) where they exist

## Output Format

For each finding, report one line:

```
file:line | category | issue | expected pattern
```

**Categories:** `naming`, `state`, `error-handling`, `audit`, `imports`, `widget`, `form`, `repository`, `model`, `structure`

Use the exact category names so findings can be filtered or grouped.

## Examples

```
lib/presentation/pages/new_page.dart:1 | imports | Third-party import before Flutter import | Group order: dart:* → flutter → packages → relative
lib/presentation/pages/new_page.dart:15 | state | Using StatefulWidget instead of ConsumerStatefulWidget | Use ConsumerStatefulWidget for forms with Riverpod access
lib/state/app_state.dart:250 | audit | Missing 'failed' phase in catch block | Add _audit?.log('...', 'failed', {'error': e.toString()}, traceId: traceId)
lib/models/new_model.dart:10 | model | Missing copyWith() method | Add copyWith() for immutable updates
lib/data/repositories/caching_foo_repository.dart:5 | naming | Class name should follow Caching*Repository | Use CachingFooRepository
lib/presentation/pages/grups_page.dart:44 | form | Direct Navigator.push used | Use context.go() or context.push() (GoRouter)
```

## Reference

- State and providers: `lib/state/app_state.dart`, `lib/state/providers.dart`
- Audit interface: `lib/core/audit/audit_logger.dart`
- Base repository: `lib/data/repositories/base_caching_repository.dart`
- Confirm dialog: `lib/presentation/widgets/confirm_dialog.dart`
- Code quality tools: `doc/code-quality/code-quality-tools.md`
