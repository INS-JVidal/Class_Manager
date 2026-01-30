#!/usr/bin/env bash
#
# setup-tools.sh — Install or verify development tools for Class Activity Manager
# (Flutter, Linux desktop) on Ubuntu and Ubuntu-based distros (e.g. KDE Neon).
# Optional: Vivaldi (Chrome-based) for web testing. Uses latest versions; skips install if
# already present and only checks versions in that case.
#
# Usage: ./setup-tools.sh
# Run with sudo if you want this script to install system packages and Flutter.
# Or run without sudo: script will only check versions and report what to install.
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
err()   { printf "${RED}[ERROR]${NC} %s\n" "$*"; }

# Check we're on a Debian-based system (Ubuntu, etc.)
check_os() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "$ID" in
      ubuntu|debian|linuxmint|pop|neon)
        ok "Detected $PRETTY_NAME"
        return 0
        ;;
      *)
        err "This script targets Ubuntu/Debian-based systems (e.g. Ubuntu, Neon, Pop). Detected: $ID"
        exit 1
        ;;
    esac
  else
    err "Cannot detect OS (/etc/os-release missing)."
    exit 1
  fi
}

# Check if a command exists and print its version; return 0 if ok, 1 if missing
check_cmd() {
  local name="$1"
  local cmd="${2:-$1}"
  local version_opt="${3:---version}"

  if command -v "$cmd" &>/dev/null; then
    local ver
    ver=$("$cmd" "$version_opt" 2>&1 | head -1)
    ok "$name is installed: $ver"
    return 0
  else
    warn "$name is not installed."
    return 1
  fi
}

# Check version of an apt package (e.g. cmake, clang)
check_apt_version() {
  local pkg="$1"
  local name="${2:-$pkg}"
  if dpkg -l "$pkg" &>/dev/null; then
    local ver
    ver=$(dpkg -s "$pkg" 2>/dev/null | awk '/^Version:/ { print $2 }')
    ok "$name is installed (apt): $ver"
    return 0
  else
    warn "$name (package $pkg) is not installed."
    return 1
  fi
}

# Install apt packages if any are missing
install_apt_packages() {
  local needed=()
  local packages=(
    curl
    git
    unzip
    xz-utils
    zip
    libglu1-mesa
    clang
    cmake
    ninja-build
    pkg-config
    libgtk-3-dev
    libstdc++-12-dev
  )

  for pkg in "${packages[@]}"; do
    if ! dpkg -l "$pkg" &>/dev/null; then
      needed+=("$pkg")
    fi
  done

  if [ ${#needed[@]} -eq 0 ]; then
    ok "All required apt packages are already installed."
    return 0
  fi

  if [ "$(id -u)" -ne 0 ]; then
    warn "Run with sudo to install missing packages: ${needed[*]}"
    info "Example: sudo apt-get update -y && sudo apt-get install -y ${needed[*]}"
    return 1
  fi

  info "Installing missing packages: ${needed[*]}"
  apt-get update -y
  apt-get install -y "${needed[@]}"
  ok "Installed: ${needed[*]}"
  return 0
}

# Check Flutter: version and Linux desktop; if not installed, optionally install via snap
check_or_install_flutter() {
  if command -v flutter &>/dev/null; then
    local ver
    ver=$(flutter --version 2>&1 | head -1)
    ok "Flutter is installed: $ver"
    info "Running: flutter doctor -v"
    flutter doctor -v || true
    info "To upgrade Flutter: flutter upgrade"
    return 0
  fi

  warn "Flutter is not installed."
  if [ "$(id -u)" -ne 0 ]; then
    info "To install Flutter (snap, latest stable): sudo snap install flutter --classic"
    info "Then run: flutter doctor -v"
    return 1
  fi

  if ! command -v snap &>/dev/null; then
    info "Installing snapd..."
    apt-get update -y
    apt-get install -y snapd
    # Ensure snap core is available
    if command -v snap &>/dev/null; then
      snap install core
    fi
  fi

  info "Installing Flutter via snap (latest stable)..."
  snap install flutter --classic
  ok "Flutter installed."
  # Ensure snap bin is in PATH (often missing when running under sudo)
  export PATH="/snap/bin:${PATH:-/usr/bin:/bin}"
  info "Run: flutter doctor -v"
  flutter doctor -v || true
  return 0
}

# Ensure Linux desktop is enabled for Flutter (if Flutter is available)
enable_flutter_linux() {
  if ! command -v flutter &>/dev/null; then
    return 0
  fi
  # Correct flag per Flutter docs: --enable-linux-desktop
  flutter config --enable-linux-desktop 2>/dev/null || true
  ok "Linux desktop enabled for Flutter (or already set)."
}

# Print versions of already-installed tools (no install)
report_versions() {
  info "--- Installed tools (version check only) ---"
  check_cmd "curl" "curl" "-V" || true
  check_cmd "git" "git" "--version" || true
  check_apt_version "unzip" "unzip" || true
  check_apt_version "xz-utils" "xz-utils" || true
  check_apt_version "zip" "zip" || true
  check_apt_version "libglu1-mesa" "libglu1-mesa" || true
  check_apt_version "cmake" "cmake" || true
  check_apt_version "clang" "clang" || true
  check_apt_version "ninja-build" "ninja" || true
  check_apt_version "pkg-config" "pkg-config" || true
  check_apt_version "libgtk-3-dev" "GTK (libgtk-3-dev)" || true
  check_apt_version "libstdc++-12-dev" "libstdc++-12-dev" || true
  check_cmd "Flutter" "flutter" "--version" || true
  check_cmd "Vivaldi (Chrome-based, for web testing)" "vivaldi" "--version" || true
}

main() {
  echo ""
  info "Class Activity Manager — setup-tools.sh (Ubuntu/Linux)"
  info "This script checks or installs: curl, git, Flutter Linux desktop deps, Flutter; optional: Vivaldi (browser)."
  echo ""

  check_os
  echo ""

  info "--- Checking existing tools ---"
  report_versions
  echo ""

  info "--- System packages (install if missing) ---"
  install_apt_packages || true
  echo ""

  info "--- Flutter ---"
  check_or_install_flutter || true
  echo ""

  enable_flutter_linux
  echo ""

  info "Done. Run 'flutter doctor -v' and fix any remaining issues."
}

main "$@"
