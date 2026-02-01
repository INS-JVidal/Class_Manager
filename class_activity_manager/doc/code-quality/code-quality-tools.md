# Code Quality Tools

This document describes the code quality tools used in the Class Activity Manager project to maintain code quality, detect duplication, and ensure maintainability.

## Table of Contents

- [jscpd - Copy/Paste Detector](#jscpd---copypaste-detector)
- [LOC Analyzer](#loc-analyzer)
- [Flutter Analyzer](#flutter-analyzer)
- [Dart Format](#dart-format)
- [Custom Lint Rules](#custom-lint-rules)
- [Review-Consistency Skill (Cursor AI)](#review-consistency-skill-cursor-ai)
- [LOC-Analyze Skill (Claude Code)](#loc-analyze-skill-claude-code)

---

## jscpd - Copy/Paste Detector

### What is jscpd?

[jscpd](https://github.com/kucherenko/jscpd) (JavaScript Copy/Paste Detector) is a tool for detecting code duplication across multiple programming languages, including Dart. It helps identify copy-pasted code that should be refactored into shared abstractions.

### Why Use jscpd?

- **Maintainability**: Duplicated code means bugs need to be fixed in multiple places
- **Consistency**: Shared code ensures consistent behavior across the application
- **Code Size**: Reducing duplication decreases the overall codebase size
- **Refactoring Opportunities**: Identifies candidates for extraction into shared utilities, base classes, or components

### Installation

```bash
# Install locally in the project (recommended)
npm install jscpd --save-dev

# Or install globally
npm install -g jscpd
```

### Running jscpd

```bash
# Basic usage
node node_modules/jscpd/bin/jscpd lib/ --min-lines 5 --min-tokens 50 --reporters console

# Generate HTML report
node node_modules/jscpd/bin/jscpd lib/ --min-lines 5 --min-tokens 50 --reporters html,console --output ./reports/duplication

# Ignore generated files
node node_modules/jscpd/bin/jscpd lib/ --ignore "**/*.g.dart,**/*.freezed.dart"
```

### Configuration Options

| Option | Description | Recommended Value |
|--------|-------------|-------------------|
| `--min-lines` | Minimum lines to consider a clone | 5 |
| `--min-tokens` | Minimum tokens to consider a clone | 50 |
| `--reporters` | Output format (console, html, json) | console,html |
| `--ignore` | Glob patterns to ignore | `**/*.g.dart` |
| `--format` | Language format | dart |

### Interpreting Results

jscpd outputs a table showing:
- **Files analyzed**: Number of source files scanned
- **Total lines/tokens**: Size of the codebase
- **Clones found**: Number of duplicate code blocks
- **Duplicated lines/tokens**: Amount and percentage of duplication

**Target**: Keep duplication under **5%** of total lines.

### Example Output

```
┌────────┬────────────────┬─────────────┬──────────────┬──────────────┬──────────────────┬───────────────────┐
│ Format │ Files analyzed │ Total lines │ Total tokens │ Clones found │ Duplicated lines │ Duplicated tokens │
├────────┼────────────────┼─────────────┼──────────────┼──────────────┼──────────────────┼───────────────────┤
│ dart   │ 63             │ 10024       │ 79727        │ 23           │ 311 (3.1%)       │ 2677 (3.36%)      │
└────────┴────────────────┴─────────────┴──────────────┴──────────────┴──────────────────┴───────────────────┘
```

---

## LOC Analyzer

### What is it?

The LOC (Lines of Code) Analyzer is a custom bash script that measures code metrics with a visual tree output. It counts lines per directory, file, and optionally per function.

### Location

`scripts/loc-analyzer.sh`

### Running LOC Analyzer

```bash
# Basic usage - analyze current directory
./scripts/loc-analyzer.sh

# Analyze lib directory
./scripts/loc-analyzer.sh lib/

# Dart files with function-level analysis
./scripts/loc-analyzer.sh -e dart -f lib/

# Summary only, limit depth to 2
./scripts/loc-analyzer.sh -d 2 -s lib/
```

### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-d, --depth N` | Maximum directory depth (default: unlimited) |
| `-e, --ext EXT` | Filter by file extension (can be used multiple times) |
| `-f, --functions` | Show function-level analysis |
| `-s, --summary` | Show only summary (no tree) |
| `-c, --no-color` | Disable colored output |
| `--exclude PATTERN` | Exclude directories matching pattern |

### Supported Languages

Function detection is supported for: Dart, JavaScript/TypeScript, Python, Go, Rust, Java, C/C++, Ruby, PHP.

### Thresholds

Use these thresholds to identify code that may need refactoring:

| Metric | Threshold | Action |
|--------|-----------|--------|
| File lines | > 500 | Consider splitting into smaller modules |
| Function lines | > 50 | Consider extraction or decomposition |
| Directory lines | > 2000 | Note for architectural review |

### Example Output

```
╭─────────────────────────────────────────────────────────────────────╮
│  lib/
│  Lines:   8234  Files:     63  Functions:    312
╰─────────────────────────────────────────────────────────────────────╯

├── data/                          [2150 lines, 89 funcs]
│   ├── repositories/              [1200 lines, 45 funcs]
│   │   ├── base_caching_repository.dart    180 lines
│   │   └── caching_group_repository.dart   245 lines
...

╔══════════════════════════════════════════════════════════════════════╗
║                           SUMMARY                                    ║
╠══════════════════════════════════════════════════════════════════════╣
║  Total Files:            63                                          ║
║  Total Lines:          8234                                          ║
║  Code Lines:           6890                                          ║
║  Blank Lines:           892                                          ║
║  Comment Lines:         452                                          ║
║  Total Functions:       312                                          ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## Flutter Analyzer

### What is it?

The Flutter/Dart analyzer performs static analysis on your code to find errors, warnings, and lint issues before runtime.

### Running the Analyzer

```bash
# Analyze entire project
flutter analyze

# Analyze specific directories
flutter analyze lib/

# Get machine-readable output
flutter analyze --no-preamble
```

### Configuration

The analyzer is configured in `analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - prefer_single_quotes
```

---

## Dart Format

### What is it?

`dart format` automatically formats Dart code according to the official Dart style guide, ensuring consistent code style across the project.

### Running Dart Format

```bash
# Format all files (in place)
dart format lib/

# Check formatting without modifying files
dart format --output=none --set-exit-if-changed lib/

# Format with specific line length
dart format --line-length=80 lib/
```

### CI Integration

Add to your CI pipeline:

```bash
dart format --output=none --set-exit-if-changed lib/ test/
```

---

## Custom Lint Rules

### Project-Specific Rules

The project uses the `lints` package with customizations in `analysis_options.yaml`:

```yaml
include: package:lints/recommended.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    # Prefer immutability
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true

    # Code clarity
    avoid_print: true
    prefer_single_quotes: true

    # Null safety
    avoid_null_checks_in_equality_operators: true
```

---

## Refactoring Patterns Applied

Based on jscpd analysis, the following refactoring patterns have been applied to reduce duplication:

### 1. Base Caching Repository

**Location**: `lib/data/repositories/base_caching_repository.dart`

Extracted common CRUD operations from 5 repository classes into a generic base class:

```dart
abstract class BaseCachingRepository<TEntity, TCache> {
  // Common: findAll(), findById(), insert(), update(), delete(), syncFromRemote()
  // Subclasses implement: toCache(), toEntity(), collection, entityType
}
```

**Impact**: ~250 lines of duplicated code eliminated.

### 2. Utility Extensions

**Location**: `lib/core/utils/`

| File | Purpose |
|------|---------|
| `color_utils.dart` | Hex color string to Color conversion |
| `string_utils.dart` | trimOrNull extension for form validation |
| `list_utils.dart` | firstWhereOrNull for safe list searching |
| `date_formats.dart` | Shared DateFormat instances |

### 3. Shared UI Components

**Location**: `lib/presentation/widgets/`

| Widget | Purpose |
|--------|---------|
| `confirm_dialog.dart` | Reusable confirmation dialogs |
| `empty_state_card.dart` | Consistent empty/info state cards |

---

## Running All Quality Checks

Create a script to run all quality checks:

```bash
#!/bin/bash
# scripts/quality-check.sh

echo "=== Dart Format Check ==="
dart format --output=none --set-exit-if-changed lib/ test/

echo "=== Flutter Analyze ==="
flutter analyze lib/

echo "=== Duplication Check ==="
node node_modules/jscpd/bin/jscpd lib/ --min-lines 5 --min-tokens 50 --reporters console --ignore "**/*.g.dart"
```

---

## Best Practices

1. **Run before commits**: Use pre-commit hooks to run format and analyze
2. **CI integration**: Add quality checks to your CI/CD pipeline
3. **Regular audits**: Run jscpd monthly to catch new duplication
4. **Refactor proactively**: When duplication exceeds 5%, prioritize refactoring
5. **Document patterns**: Document reusable patterns in code and docs

---

## Review-Consistency Skill (Cursor AI)

The project includes a Cursor skill that reviews code for consistency with project patterns (naming, Riverpod, audit logging, widgets, etc.). It is triggered from Cursor chat when you ask for a consistency review.

**User guide:** [review-consistency-skill-user-guide.md](review-consistency-skill-user-guide.md) — what the skill does and how to use it.

**Skill definition:** `.cursor/skills/review-consistency/SKILL.md`

---

## LOC-Analyze Skill (Claude Code)

The project includes a Claude Code skill that runs the LOC analyzer and interprets results. It is triggered from Claude Code chat using `/loc-analyze`.

### Usage

```
/loc-analyze                    # Analyze lib/ with defaults
/loc-analyze lib/presentation   # Specific directory
/loc-analyze -f                 # Include function analysis
/loc-analyze -s                 # Summary only
```

### What It Does

1. Runs `scripts/loc-analyzer.sh` with the requested options
2. Presents key findings (total lines, largest files, function counts)
3. Suggests actions when files/functions exceed thresholds

**Skill definition:** `.cursor/skills/loc-analyze/SKILL.md`

---

## References

- [jscpd GitHub](https://github.com/kucherenko/jscpd)
- [Dart Analysis Options](https://dart.dev/tools/analysis)
- [Effective Dart Style Guide](https://dart.dev/effective-dart/style)
- [Flutter Code Quality](https://docs.flutter.dev/perf/best-practices)
- [Review-Consistency Skill — User Guide](review-consistency-skill-user-guide.md)
