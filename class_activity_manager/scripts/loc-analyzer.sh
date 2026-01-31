#!/usr/bin/env bash
#
# loc-analyzer.sh - Lines of Code Analyzer
# Measures LOC per directory, file, and function with UTF-8 tree output
#
# Usage: ./loc-analyzer.sh [OPTIONS] [PATH]
#
# Options:
#   -h, --help          Show this help message
#   -d, --depth N       Maximum directory depth (default: unlimited)
#   -e, --ext EXT       Filter by file extension (e.g., -e dart -e py)
#   -f, --functions     Show function-level analysis
#   -s, --summary       Show only summary (no tree)
#   -c, --no-color      Disable colored output
#   --exclude PATTERN   Exclude directories matching pattern
#

set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

# UTF-8 tree characters
readonly TREE_PIPE="│"
readonly TREE_TEE="├──"
readonly TREE_CORNER="└──"
readonly TREE_SPACE="   "
readonly TREE_LINE="───"

# Colors (ANSI escape codes)
COLOR_DIR="\033[1;34m"      # Bold Blue
COLOR_FILE="\033[0;37m"     # White
COLOR_FUNC="\033[0;36m"     # Cyan
COLOR_NUM="\033[1;33m"      # Bold Yellow
COLOR_HEADER="\033[1;35m"   # Bold Magenta
COLOR_RESET="\033[0m"
COLOR_DIM="\033[2m"         # Dim
COLOR_GREEN="\033[0;32m"    # Green
COLOR_RED="\033[0;31m"      # Red

# Default options
MAX_DEPTH=-1
SHOW_FUNCTIONS=false
SUMMARY_ONLY=false
USE_COLOR=true
EXTENSIONS=()
EXCLUDE_PATTERNS=(".git" "build" "node_modules" ".dart_tool" "__pycache__" ".venv" "vendor")

# Counters
TOTAL_FILES=0
TOTAL_LINES=0
TOTAL_FUNCTIONS=0
TOTAL_BLANK=0
TOTAL_COMMENT=0

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                         LOC ANALYZER - Code Metrics Tool                      ║
╚══════════════════════════════════════════════════════════════════════════════╝

USAGE:
    ./loc-analyzer.sh [OPTIONS] [PATH]

OPTIONS:
    -h, --help              Show this help message
    -d, --depth N           Maximum directory depth (default: unlimited)
    -e, --ext EXT           Filter by file extension (can be used multiple times)
                            Example: -e dart -e py -e js
    -f, --functions         Show function-level analysis (slower)
    -s, --summary           Show only summary statistics
    -c, --no-color          Disable colored output
    --exclude PATTERN       Exclude directories matching pattern
                            Example: --exclude test --exclude build

EXAMPLES:
    ./loc-analyzer.sh                       # Analyze current directory
    ./loc-analyzer.sh lib/                  # Analyze lib directory
    ./loc-analyzer.sh -e dart -f lib/       # Dart files with functions
    ./loc-analyzer.sh -d 2 -s               # Summary only, depth 2

OUTPUT:
    The tool displays a tree structure showing:
    • Directory totals (sum of all files within)
    • File line counts
    • Function line counts (with -f flag)

SUPPORTED LANGUAGES (for function detection):
    Dart, JavaScript/TypeScript, Python, Go, Rust, Java, C/C++, Ruby, PHP

EOF
}

# Disable colors if requested or if not a terminal
setup_colors() {
    if [[ "$USE_COLOR" == false ]] || [[ ! -t 1 ]]; then
        COLOR_DIR=""
        COLOR_FILE=""
        COLOR_FUNC=""
        COLOR_NUM=""
        COLOR_HEADER=""
        COLOR_RESET=""
        COLOR_DIM=""
        COLOR_GREEN=""
        COLOR_RED=""
    fi
}

# Count lines in a file (excluding blank lines optionally)
count_lines() {
    local file="$1"
    local total=0
    local blank=0
    local comment=0
    local code=0

    if [[ ! -f "$file" ]]; then
        echo "0 0 0 0"
        return
    fi

    # Get total lines (strip whitespace from wc output)
    total=$(wc -l < "$file" 2>/dev/null)
    total=${total//[[:space:]]/}
    total=${total:-0}

    # Count blank lines
    blank=$(grep -c '^[[:space:]]*$' "$file" 2>/dev/null) || blank=0
    blank=${blank//[[:space:]]/}
    blank=${blank:-0}

    # Detect comment style based on extension
    local ext="${file##*.}"
    case "$ext" in
        dart|js|ts|java|go|rs|c|cpp|h|hpp|swift|kt)
            comment=$(grep -cE '^\s*(//|/\*|\*)' "$file" 2>/dev/null) || comment=0
            ;;
        py|rb|sh|bash|yaml|yml)
            comment=$(grep -cE '^\s*#' "$file" 2>/dev/null) || comment=0
            ;;
        html|xml)
            comment=$(grep -cE '^\s*<!--' "$file" 2>/dev/null) || comment=0
            ;;
        *)
            comment=0
            ;;
    esac
    comment=${comment//[[:space:]]/}
    comment=${comment:-0}

    code=$((total - blank - comment))
    [[ $code -lt 0 ]] && code=0

    echo "$total $blank $comment $code"
}

# Extract functions from a file
extract_functions() {
    local file="$1"
    local ext="${file##*.}"

    case "$ext" in
        dart)
            # Dart: class methods, top-level functions, getters, setters
            grep -nE '^\s*(static\s+)?(Future|Stream|void|bool|int|double|String|List|Map|Set|dynamic|var|final|const|[A-Z][a-zA-Z0-9_]*(<[^>]+>)?)\s+[a-z_][a-zA-Z0-9_]*\s*[\(<]|^\s*(get|set)\s+[a-z]' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):.*\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*[\(<].*/\1:\2/' | \
            grep -E '^[0-9]+:[a-zA-Z_]'
            ;;
        js|ts|jsx|tsx)
            # JavaScript/TypeScript: function declarations, arrow functions, methods
            grep -nE '^\s*(async\s+)?function\s+[a-zA-Z_]|^\s*(const|let|var)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*(async\s+)?\(|^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\([^)]*\)\s*\{' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):.*function\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1:\2/' | \
            sed -E 's/^([0-9]+):.*(const|let|var)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=.*/\1:\3/' | \
            grep -E '^[0-9]+:[a-zA-Z_]'
            ;;
        py)
            # Python: def and async def
            grep -nE '^\s*(async\s+)?def\s+[a-zA-Z_]' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):.*def\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1:\2/'
            ;;
        go)
            # Go: func declarations
            grep -nE '^func\s+(\([^)]+\)\s+)?[a-zA-Z_]' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):func\s+(\([^)]+\)\s+)?([a-zA-Z_][a-zA-Z0-9_]*).*/\1:\3/'
            ;;
        rs)
            # Rust: fn declarations
            grep -nE '^\s*(pub\s+)?(async\s+)?fn\s+[a-z_]' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):.*fn\s+([a-z_][a-zA-Z0-9_]*).*/\1:\2/'
            ;;
        java|kt)
            # Java/Kotlin: method declarations
            grep -nE '^\s*(public|private|protected|static|final|override|suspend)?\s*(public|private|protected|static|final|override|suspend)?\s*(void|boolean|int|long|double|float|String|[A-Z][a-zA-Z0-9_<>,\s]*)\s+[a-z][a-zA-Z0-9_]*\s*\(' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):.*\s+([a-z][a-zA-Z0-9_]*)\s*\(.*/\1:\2/'
            ;;
        c|cpp|h|hpp)
            # C/C++: function definitions
            grep -nE '^[a-zA-Z_][a-zA-Z0-9_*\s]+\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\([^;]*$' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):.*\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(.*/\1:\2/'
            ;;
        rb)
            # Ruby: def declarations
            grep -nE '^\s*def\s+[a-zA-Z_]' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):.*def\s+([a-zA-Z_][a-zA-Z0-9_?!]*).*/\1:\2/'
            ;;
        php)
            # PHP: function declarations
            grep -nE '^\s*(public|private|protected|static)?\s*function\s+[a-zA-Z_]' "$file" 2>/dev/null | \
            sed -E 's/^([0-9]+):.*function\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1:\2/'
            ;;
        *)
            # Unknown extension, skip
            ;;
    esac
}

# Calculate function line counts
get_function_lines() {
    local file="$1"
    local func_data
    func_data=$(extract_functions "$file")

    if [[ -z "$func_data" ]]; then
        return
    fi

    local total_lines
    total_lines=$(wc -l < "$file" 2>/dev/null | tr -d ' ' || echo 0)

    local prev_line=0
    local prev_name=""
    local results=()

    while IFS=: read -r line_num func_name; do
        [[ -z "$line_num" ]] && continue

        if [[ $prev_line -gt 0 ]] && [[ -n "$prev_name" ]]; then
            local func_lines=$((line_num - prev_line))
            results+=("$prev_name:$func_lines")
        fi

        prev_line=$line_num
        prev_name=$func_name
    done <<< "$func_data"

    # Handle last function
    if [[ $prev_line -gt 0 ]] && [[ -n "$prev_name" ]]; then
        local func_lines=$((total_lines - prev_line + 1))
        results+=("$prev_name:$func_lines")
    fi

    printf '%s\n' "${results[@]}"
}

# Format number with color based on size
format_number() {
    local num=${1:-0}
    local width=${2:-6}

    # Ensure num is a valid number
    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        num=0
    fi

    if [[ $num -ge 1000 ]]; then
        printf "${COLOR_RED}%${width}d${COLOR_RESET}" "$num"
    elif [[ $num -ge 100 ]]; then
        printf "${COLOR_NUM}%${width}d${COLOR_RESET}" "$num"
    else
        printf "${COLOR_GREEN}%${width}d${COLOR_RESET}" "$num"
    fi
}

# Check if directory should be excluded
is_excluded() {
    local dir="$1"
    local basename
    basename=$(basename "$dir")

    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$basename" == "$pattern" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if file matches extension filter
matches_extension() {
    local file="$1"

    if [[ ${#EXTENSIONS[@]} -eq 0 ]]; then
        return 0
    fi

    local ext="${file##*.}"
    for e in "${EXTENSIONS[@]}"; do
        if [[ "$ext" == "$e" ]]; then
            return 0
        fi
    done
    return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Tree Display Functions
# ─────────────────────────────────────────────────────────────────────────────

# Print tree prefix
print_prefix() {
    local prefix="$1"
    echo -n "$prefix"
}

# Analyze and display a directory
analyze_directory() {
    local dir="$1"
    local prefix="$2"
    local depth="$3"
    local is_last="$4"

    local dir_name
    dir_name=$(basename "$dir")

    # Check depth limit
    if [[ $MAX_DEPTH -ge 0 ]] && [[ $depth -gt $MAX_DEPTH ]]; then
        return 0
    fi

    # Collect items in directory
    local items=()
    local dirs=()
    local files=()

    while IFS= read -r -d '' item; do
        local item_name
        item_name=$(basename "$item")

        if [[ -d "$item" ]]; then
            if ! is_excluded "$item"; then
                dirs+=("$item")
            fi
        elif [[ -f "$item" ]]; then
            if matches_extension "$item"; then
                files+=("$item")
            fi
        fi
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | sort -z)

    # Sort arrays
    IFS=$'\n' dirs=($(sort <<< "${dirs[*]}")); unset IFS
    IFS=$'\n' files=($(sort <<< "${files[*]}")); unset IFS

    # Combine for iteration
    items=("${dirs[@]}" "${files[@]}")

    # Calculate directory totals
    local dir_lines=0
    local dir_files=0
    local dir_functions=0

    for f in "${files[@]}"; do
        [[ -z "$f" ]] && continue
        local line_data
        line_data=$(count_lines "$f")
        local lines
        lines=$(echo "$line_data" | cut -d' ' -f1)
        dir_lines=$((dir_lines + lines))
        dir_files=$((dir_files + 1))

        if [[ "$SHOW_FUNCTIONS" == true ]]; then
            local func_count
            func_count=$(extract_functions "$f" 2>/dev/null | wc -l | tr -d ' ')
            func_count=${func_count:-0}
            dir_functions=$((dir_functions + func_count))
        fi
    done

    # Recurse into subdirectories for totals
    for d in "${dirs[@]}"; do
        [[ -z "$d" ]] && continue
        local subdir_stats
        subdir_stats=$(calculate_dir_stats "$d")
        local sub_lines sub_files sub_funcs
        sub_lines=$(echo "$subdir_stats" | cut -d' ' -f1)
        sub_files=$(echo "$subdir_stats" | cut -d' ' -f2)
        sub_funcs=$(echo "$subdir_stats" | cut -d' ' -f3)
        dir_lines=$((dir_lines + sub_lines))
        dir_files=$((dir_files + sub_files))
        dir_functions=$((dir_functions + sub_funcs))
    done

    # Print directory line
    if [[ $depth -eq 0 ]]; then
        echo -e "${COLOR_HEADER}╭─────────────────────────────────────────────────────────────────────╮${COLOR_RESET}"
        echo -e "${COLOR_HEADER}│${COLOR_RESET}  ${COLOR_DIR}$dir_name/${COLOR_RESET}"
        printf "${COLOR_HEADER}│${COLOR_RESET}  Lines: $(format_number $dir_lines)  Files: $(format_number $dir_files)"
        if [[ "$SHOW_FUNCTIONS" == true ]]; then
            printf "  Functions: $(format_number $dir_functions)"
        fi
        echo -e "\n${COLOR_HEADER}╰─────────────────────────────────────────────────────────────────────╯${COLOR_RESET}"
        echo ""
    else
        local connector="$TREE_TEE"
        [[ "$is_last" == "true" ]] && connector="$TREE_CORNER"

        printf "${prefix}${connector} ${COLOR_DIR}%-30s${COLOR_RESET} " "$dir_name/"
        printf "[$(format_number $dir_lines) lines"
        if [[ "$SHOW_FUNCTIONS" == true ]] && [[ $dir_functions -gt 0 ]]; then
            printf ", $(format_number $dir_functions) funcs"
        fi
        echo "]"
    fi

    # Update totals (only count files at this level, subdirs recurse)
    TOTAL_FILES=$((TOTAL_FILES + ${#files[@]}))

    # Build new prefix for children
    local child_prefix="$prefix"
    if [[ $depth -gt 0 ]]; then
        if [[ "$is_last" == "true" ]]; then
            child_prefix="${prefix}${TREE_SPACE} "
        else
            child_prefix="${prefix}${TREE_PIPE}  "
        fi
    fi

    # Process children
    local total_items=${#items[@]}
    local current=0

    for item in "${items[@]}"; do
        [[ -z "$item" ]] && continue
        current=$((current + 1))
        local item_is_last="false"
        [[ $current -eq $total_items ]] && item_is_last="true"

        if [[ -d "$item" ]]; then
            analyze_directory "$item" "$child_prefix" $((depth + 1)) "$item_is_last"
        elif [[ -f "$item" ]]; then
            analyze_file "$item" "$child_prefix" "$item_is_last"
        fi
    done
}

# Calculate directory statistics recursively (for parent totals)
calculate_dir_stats() {
    local dir="$1"
    local total_lines=0
    local total_files=0
    local total_funcs=0

    while IFS= read -r -d '' item; do
        if [[ -d "$item" ]]; then
            if ! is_excluded "$item"; then
                local sub_stats
                sub_stats=$(calculate_dir_stats "$item")
                local sub_l sub_f sub_fn
                sub_l=$(echo "$sub_stats" | cut -d' ' -f1)
                sub_f=$(echo "$sub_stats" | cut -d' ' -f2)
                sub_fn=$(echo "$sub_stats" | cut -d' ' -f3)
                total_lines=$((total_lines + sub_l))
                total_files=$((total_files + sub_f))
                total_funcs=$((total_funcs + sub_fn))
            fi
        elif [[ -f "$item" ]]; then
            if matches_extension "$item"; then
                local line_data
                line_data=$(count_lines "$item")
                local lines
                lines=$(echo "$line_data" | cut -d' ' -f1)
                total_lines=$((total_lines + lines))
                total_files=$((total_files + 1))

                if [[ "$SHOW_FUNCTIONS" == true ]]; then
                    local fc
                    fc=$(extract_functions "$item" 2>/dev/null | wc -l | tr -d ' ')
                    fc=${fc:-0}
                    total_funcs=$((total_funcs + fc))
                fi
            fi
        fi
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)

    echo "$total_lines $total_files $total_funcs"
}

# Analyze and display a file
analyze_file() {
    local file="$1"
    local prefix="$2"
    local is_last="$3"

    local file_name
    file_name=$(basename "$file")

    local line_data
    line_data=$(count_lines "$file")
    local total blank comment code
    read -r total blank comment code <<< "$line_data"

    TOTAL_LINES=$((TOTAL_LINES + total))
    TOTAL_BLANK=$((TOTAL_BLANK + blank))
    TOTAL_COMMENT=$((TOTAL_COMMENT + comment))

    local connector="$TREE_TEE"
    [[ "$is_last" == "true" ]] && connector="$TREE_CORNER"

    # Print file line
    printf "${prefix}${connector} ${COLOR_FILE}%-30s${COLOR_RESET} " "$file_name"
    printf "$(format_number $total) lines"
    if [[ $comment -gt 0 ]]; then
        printf " ${COLOR_DIM}($comment comments)${COLOR_RESET}"
    fi
    echo ""

    # Show functions if requested
    if [[ "$SHOW_FUNCTIONS" == true ]]; then
        local child_prefix="$prefix"
        if [[ "$is_last" == "true" ]]; then
            child_prefix="${prefix}${TREE_SPACE} "
        else
            child_prefix="${prefix}${TREE_PIPE}  "
        fi

        local functions
        functions=$(get_function_lines "$file")

        if [[ -n "$functions" ]]; then
            local func_array=()
            while IFS= read -r line; do
                [[ -n "$line" ]] && func_array+=("$line")
            done <<< "$functions"

            local func_count=${#func_array[@]}
            local func_idx=0

            TOTAL_FUNCTIONS=$((TOTAL_FUNCTIONS + func_count))

            for func_line in "${func_array[@]}"; do
                func_idx=$((func_idx + 1))
                local func_name="${func_line%%:*}"
                local func_lines="${func_line##*:}"

                local func_connector="$TREE_TEE"
                [[ $func_idx -eq $func_count ]] && func_connector="$TREE_CORNER"

                printf "${child_prefix}${func_connector} ${COLOR_FUNC}%-28s${COLOR_RESET} " "$func_name()"
                printf "$(format_number $func_lines 4) lines\n"
            done
        fi
    fi
}

# Print summary statistics
print_summary() {
    echo ""
    echo -e "${COLOR_HEADER}╔══════════════════════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_HEADER}║                           SUMMARY                                    ║${COLOR_RESET}"
    echo -e "${COLOR_HEADER}╠══════════════════════════════════════════════════════════════════════╣${COLOR_RESET}"
    printf "${COLOR_HEADER}║${COLOR_RESET}  Total Files:      $(format_number $TOTAL_FILES 8)                                       ${COLOR_HEADER}║${COLOR_RESET}\n"
    printf "${COLOR_HEADER}║${COLOR_RESET}  Total Lines:      $(format_number $TOTAL_LINES 8)                                       ${COLOR_HEADER}║${COLOR_RESET}\n"
    printf "${COLOR_HEADER}║${COLOR_RESET}  Code Lines:       $(format_number $((TOTAL_LINES - TOTAL_BLANK - TOTAL_COMMENT)) 8)                                       ${COLOR_HEADER}║${COLOR_RESET}\n"
    printf "${COLOR_HEADER}║${COLOR_RESET}  Blank Lines:      $(format_number $TOTAL_BLANK 8)                                       ${COLOR_HEADER}║${COLOR_RESET}\n"
    printf "${COLOR_HEADER}║${COLOR_RESET}  Comment Lines:    $(format_number $TOTAL_COMMENT 8)                                       ${COLOR_HEADER}║${COLOR_RESET}\n"
    if [[ "$SHOW_FUNCTIONS" == true ]]; then
        printf "${COLOR_HEADER}║${COLOR_RESET}  Total Functions:  $(format_number $TOTAL_FUNCTIONS 8)                                       ${COLOR_HEADER}║${COLOR_RESET}\n"
    fi
    echo -e "${COLOR_HEADER}╚══════════════════════════════════════════════════════════════════════╝${COLOR_RESET}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    local target_path="."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--depth)
                MAX_DEPTH="$2"
                shift 2
                ;;
            -e|--ext)
                EXTENSIONS+=("$2")
                shift 2
                ;;
            -f|--functions)
                SHOW_FUNCTIONS=true
                shift
                ;;
            -s|--summary)
                SUMMARY_ONLY=true
                shift
                ;;
            -c|--no-color)
                USE_COLOR=false
                shift
                ;;
            --exclude)
                EXCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use -h or --help for usage information."
                exit 1
                ;;
            *)
                target_path="$1"
                shift
                ;;
        esac
    done

    # Setup
    setup_colors

    # Validate target path
    if [[ ! -e "$target_path" ]]; then
        echo "Error: Path '$target_path' does not exist."
        exit 1
    fi

    # Resolve to absolute path
    target_path=$(cd "$target_path" 2>/dev/null && pwd)

    echo ""
    echo -e "${COLOR_HEADER}  LOC ANALYZER${COLOR_RESET} - $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "  ${COLOR_DIM}Analyzing: $target_path${COLOR_RESET}"
    if [[ ${#EXTENSIONS[@]} -gt 0 ]]; then
        echo -e "  ${COLOR_DIM}Extensions: ${EXTENSIONS[*]}${COLOR_RESET}"
    fi
    echo ""

    if [[ "$SUMMARY_ONLY" == false ]]; then
        # Full tree analysis
        if [[ -d "$target_path" ]]; then
            analyze_directory "$target_path" "" 0 "false"
        else
            analyze_file "$target_path" "" "true"
        fi
    else
        # Summary only - just calculate totals
        if [[ -d "$target_path" ]]; then
            while IFS= read -r -d '' file; do
                if matches_extension "$file"; then
                    local line_data
                    line_data=$(count_lines "$file")
                    local total blank comment code
                    read -r total blank comment code <<< "$line_data"
                    TOTAL_FILES=$((TOTAL_FILES + 1))
                    TOTAL_LINES=$((TOTAL_LINES + total))
                    TOTAL_BLANK=$((TOTAL_BLANK + blank))
                    TOTAL_COMMENT=$((TOTAL_COMMENT + comment))

                    if [[ "$SHOW_FUNCTIONS" == true ]]; then
                        local fc
                        fc=$(extract_functions "$file" 2>/dev/null | wc -l | tr -d ' ')
                        fc=${fc:-0}
                        TOTAL_FUNCTIONS=$((TOTAL_FUNCTIONS + fc))
                    fi
                fi
            done < <(find "$target_path" -type f -print0 2>/dev/null)
        fi
    fi

    # Print summary
    print_summary
}

main "$@"
