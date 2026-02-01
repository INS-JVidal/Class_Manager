---
name: review-robustness
description: Review Flutter/Dart code for robustness including error handling, input validation, network/IO resilience, and edge-case coverage. Use when reviewing code changes, PRs, or when the user asks to check error handling, robustness, or defensive coding.
---

# Review Robustness (Flutter / Class Activity Manager)

Reviews code for robustness: error handling, input validation, network/IO resilience, and edge-case coverage. Apply to files, diffs, or folders when the user requests a robustness review.

## Instructions

1. Read the target file(s), diff, or folder.
2. Check each category in the checklist below against the code.
3. Report findings in the output format. Omit categories with no issues.
4. Cite file and line (or method name) for each finding.

## Checklist

### 1. Error Handling

- [ ] **Try-catch coverage**: Async operations that can fail (network, IO, parsing) are wrapped in try-catch
- [ ] **No silent swallowing**: Catch blocks do not silently ignore errors; at minimum log or rethrow
- [ ] **Rethrow after logging**: When catching to log, rethrow so callers can handle
- [ ] **Specific exceptions**: Catch specific exception types where possible (e.g. `on FormatException`, `on SocketException`)
- [ ] **Finally for cleanup**: Use `finally` to release resources (close streams, reset flags) regardless of success/failure
- [ ] **Graceful degradation**: When remote fails, fall back to local cache or defaults where applicable

### 2. Input Validation

- [ ] **Null checks**: External input (JSON, user input, function params) is checked for null before use
- [ ] **Empty checks**: Strings and collections are checked for empty before processing (e.g. `if (name.isEmpty) return;`)
- [ ] **Type checks**: Use safe casts (`as Type?`) or type checks (`is Type`) before casting
- [ ] **Safe parsing**: Use `int.tryParse()`, `double.tryParse()`, `DateTime.tryParse()` instead of throwing variants
- [ ] **Trim user input**: Trim whitespace from text fields before validation and storage
- [ ] **Sanitize external data**: Validate and sanitize data from external sources (API, file, user) before use

### 3. Network and IO Resilience

- [ ] **Connection checks**: Verify connection state before network/database operations
- [ ] **Timeouts**: Network and IO operations have timeouts (or use libraries that provide them)
- [ ] **Retry logic**: Transient failures (network blips) are retried with limits (e.g. max 3 retries)
- [ ] **Offline fallback**: When network is unavailable, fall back to local cache or queue for later
- [ ] **State validation**: Check that datasources are initialized before use (e.g. `if (_db == null) throw StateError(...)`)
- [ ] **Environment validation**: Required environment variables are checked at startup

### 4. Edge Cases

- [ ] **Empty collections**: Handle empty lists/maps gracefully (don't assume `.first` exists)
- [ ] **Null optionals**: Handle nullable fields (e.g. `ra.startDate == null`)
- [ ] **Boundary values**: Validate boundary conditions (e.g. `hours <= 0`, date ranges, index bounds)
- [ ] **Default values**: Provide sensible defaults for missing or invalid data
- [ ] **List operations**: Use safe list access (`.firstOrNull`, `.elementAtOrNull`, or check `.isEmpty` first)
- [ ] **Date boundaries**: Validate that start date is before end date; handle same-day edge case

### 5. External Data Parsing

- [ ] **JSON null safety**: Use `json['key'] as Type?` with null checks or defaults
- [ ] **Nested parsing**: Wrap nested JSON/YAML parsing in try-catch or use null-safe access
- [ ] **DateTime parsing**: Use `DateTime.tryParse()` or wrap `DateTime.parse()` in try-catch
- [ ] **List casting**: Use `?.cast<T>()` or `?.map(...)` with null checks for JSON arrays
- [ ] **Version/schema handling**: Handle missing or unexpected fields gracefully (backwards compatibility)
- [ ] **Encoding errors**: Wrap `jsonEncode`/`jsonDecode` in try-catch for malformed data

## Output Format

For each finding, report one line:

```
file:line | category | issue | suggested fix
```

**Categories:** `error-handling`, `input-validation`, `network-io`, `edge-case`, `parsing`

Use the exact category names so findings can be filtered or grouped.

## Severity Guide

- **Critical**: Can cause crash, data loss, or security issue (e.g. unhandled exception in production path)
- **Warning**: Potential issue under certain conditions (e.g. missing null check on optional field)
- **Info**: Defensive improvement (e.g. could add timeout, could use tryParse)

## Examples

```
lib/data/services/cache_service.dart:132 | parsing | jsonDecode without try-catch | Wrap in try-catch to handle malformed JSON
lib/presentation/pages/moduls_page.dart:185 | input-validation | Silent return on invalid input | Show user feedback (e.g. SnackBar) instead of silent failure
lib/models/ra.dart:93 | parsing | DateTime.parse without try-catch | Use DateTime.tryParse() or wrap in try-catch
lib/state/app_state.dart:162 | edge-case | Assumes list is non-empty before .first | Check .isEmpty or use .firstOrNull
lib/data/datasources/mongodb_datasource.dart:45 | network-io | No timeout on database query | Add timeout or use library with configurable timeout
lib/presentation/pages/grups_page.dart:295 | input-validation | Empty name check returns silently | Disable save button or show validation error
```

## Reference

- Error handling in state: `lib/state/app_state.dart` (try-catch with fallback and rethrow)
- Sync retry logic: `lib/data/services/cache_service.dart` (retry with limits, conflict handling)
- JSON parsing: `lib/models/modul.dart`, `lib/models/ra.dart` (null-safe parsing with defaults)
- Input validation: `lib/presentation/pages/moduls_page.dart`, `lib/presentation/pages/grups_page.dart`
- Date validation: `lib/presentation/widgets/dual_date_picker.dart`
