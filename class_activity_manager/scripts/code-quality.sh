#!/usr/bin/env bash
#
# Code Quality Analysis Tool — Class Activity Manager
# Runs analyze, format check, tests, coverage, and dependency check.
# Displays a summary of metrics in the terminal.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Metrics
ANALYZE_EXIT=0
FORMAT_EXIT=0
TEST_EXIT=0
COVERAGE_PCT="N/A"
OUTDATED_COUNT=0
ISSUE_COUNT=""

echo ""
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║          Class Activity Manager — Code Quality Report        ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Flutter analyze
echo -e "${BLUE}[1/5] Running flutter analyze...${NC}"
if ANALYZE_OUTPUT=$(flutter analyze 2>&1); then
  ANALYZE_EXIT=0
  echo -e "      ${GREEN}✓ No issues found${NC}"
else
  ANALYZE_EXIT=$?
  ISSUE_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -oE "[0-9]+ issues? found" | grep -oE "[0-9]+" | head -1 || echo "?")
  echo -e "      ${RED}✗ Issues found${NC} (${ISSUE_COUNT} issues)"
  echo "$ANALYZE_OUTPUT" | tail -20 | sed 's/^/      /'
fi
echo ""

# 2. Dart format check
echo -e "${BLUE}[2/5] Checking dart format...${NC}"
if dart format --set-exit-if-changed lib/ test/ 2>/dev/null; then
  FORMAT_EXIT=0
  echo -e "      ${GREEN}✓ Code is formatted${NC}"
else
  FORMAT_EXIT=$?
  echo -e "      ${YELLOW}⚠ Files need formatting (run: dart format lib/ test/)${NC}"
fi
echo ""

# 3. Flutter test
echo -e "${BLUE}[3/5] Running flutter test...${NC}"
if TEST_OUTPUT=$(flutter test 2>&1); then
  TEST_EXIT=0
  PASSED=$(echo "$TEST_OUTPUT" | grep -oE '\+[0-9]+' | tail -1 | tr -d '+' || echo "?")
  echo -e "      ${GREEN}✓ All tests passed${NC} (${PASSED:-?} passed)"
else
  TEST_EXIT=$?
  echo -e "      ${RED}✗ Tests failed (exit $TEST_EXIT)${NC}"
  echo "$TEST_OUTPUT" | tail -15 | sed 's/^/      /'
fi
echo ""

# 4. Coverage (if tests passed)
echo -e "${BLUE}[4/5] Running test coverage...${NC}"
if [ "$TEST_EXIT" -eq 0 ]; then
  if COV_OUTPUT=$(flutter test --coverage 2>&1); then
    if [ -f coverage/lcov.info ] && command -v lcov &>/dev/null; then
      COVERAGE_PCT=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines" | grep -oP '\d+\.\d+' | head -1 || echo "N/A")
      echo -e "      ${GREEN}✓ Coverage: ${COVERAGE_PCT}%${NC}"
    elif [ -f coverage/lcov.info ]; then
      # Simple parse without lcov: count covered/total lines
      TOTAL=$(grep -c "^DA:" coverage/lcov.info 2>/dev/null || echo "0")
      HIT=$(grep "^DA:" coverage/lcov.info 2>/dev/null | grep -v ",0$" | wc -l)
      if [ "$TOTAL" -gt 0 ]; then
        COVERAGE_PCT=$(awk "BEGIN {printf \"%.1f\", ($HIT/$TOTAL)*100}")
        echo -e "      ${GREEN}✓ Coverage: ~${COVERAGE_PCT}%${NC} (lines)"
      else
        echo -e "      ${CYAN}○ Coverage file generated (install lcov for summary)${NC}"
      fi
    else
      echo -e "      ${CYAN}○ Coverage file generated${NC}"
    fi
  else
    echo -e "      ${YELLOW}⚠ Coverage run failed${NC}"
  fi
else
  echo -e "      ${YELLOW}○ Skipped (tests failed)${NC}"
fi
echo ""

# 5. Pub outdated
echo -e "${BLUE}[5/5] Checking dependencies...${NC}"
if OUTDATED_OUTPUT=$(dart pub outdated 2>&1); then
  # Count packages with upgrades available
  OUTDATED_COUNT=$(echo "$OUTDATED_OUTPUT" | grep -c "upgradable" 2>/dev/null || true)
  OUTDATED_COUNT=${OUTDATED_COUNT:-0}
  if [ "${OUTDATED_COUNT:-0}" -eq 0 ]; then
    echo -e "      ${GREEN}✓ All dependencies up to date${NC}"
  else
    echo -e "      ${YELLOW}⚠ $OUTDATED_COUNT package(s) have newer versions${NC}"
  fi
else
  echo -e "      ${YELLOW}⚠ Could not check dependencies${NC}"
fi
echo ""

# Summary table
echo -e "${BOLD}${CYAN}─────────────────────────────────────────────────────────────────${NC}"
echo -e "${BOLD}                         SUMMARY${NC}"
echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
if [ $ANALYZE_EXIT -eq 0 ]; then
  printf "  %-25s %s\n" "Analyze:" "$(echo -e "${GREEN}✓ OK${NC}")"
else
  printf "  %-25s %s\n" "Analyze:" "$(echo -e "${RED}✗ Failed${NC}") (${ISSUE_COUNT:-?} issues)"
fi
printf "  %-25s %s\n" "Format:"  "$([ $FORMAT_EXIT -eq 0 ] && echo -e "${GREEN}✓ OK${NC}" || echo -e "${YELLOW}⚠ Needs format${NC}")"
printf "  %-25s %s\n" "Tests:"   "$([ $TEST_EXIT -eq 0 ] && echo -e "${GREEN}✓ Passed${NC}" || echo -e "${RED}✗ Failed${NC}")"
printf "  %-25s %s\n" "Coverage:" "$COVERAGE_PCT%"
printf "  %-25s %s\n" "Outdated packages:" "$([ "${OUTDATED_COUNT:-0}" -eq 0 ] && echo -e "${GREEN}0${NC}" || echo -e "${YELLOW}$OUTDATED_COUNT${NC}")"
echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
echo ""

# Exit with failure if any critical check failed
if [ $ANALYZE_EXIT -ne 0 ] || [ $TEST_EXIT -ne 0 ]; then
  echo -e "${RED}Code quality check failed. Fix analyze and/or test issues.${NC}"
  exit 1
fi

echo -e "${GREEN}Code quality check passed.${NC}"
exit 0
