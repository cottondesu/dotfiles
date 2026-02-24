#!/usr/bin/env bash
# =============================================================================
# Manual Test Suite for install.sh
# =============================================================================
# 
# このスクリプトは install.sh の静的解析を行います。
# システム全体には変更を加えません。
#
# 使用方法:
#   bash manual_test.sh
#
# 注意: Bats がインストールされていない環境でのクイックチェック用です。
#       完全なテストスイートは test_runner.sh を使用してください。
#
# =============================================================================

set -euo pipefail

# =============================================================================
# Constants
# =============================================================================
readonly SCRIPT_NAME="Manual Test Suite"
readonly SCRIPT_VERSION="2.0.0"
readonly TARGET_SCRIPT="./install.sh"

# =============================================================================
# Test Counters
# =============================================================================
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# =============================================================================
# Color Codes
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# Utility Functions
# =============================================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++)) || true
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++)) || true
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((SKIPPED_TESTS++)) || true
}

run_test() {
    local test_name="$1"
    local test_result="$2"
    
    ((TOTAL_TESTS++)) || true
    
    if [[ "$test_result" == "pass" ]]; then
        log_pass "$test_name"
    elif [[ "$test_result" == "skip" ]]; then
        log_skip "$test_name"
    else
        log_fail "$test_name"
    fi
}

# =============================================================================
# Header
# =============================================================================
echo "=========================================="
echo "  $SCRIPT_NAME v$SCRIPT_VERSION"
echo "=========================================="
echo ""
log_info "Target: $TARGET_SCRIPT"
echo ""

# =============================================================================
# Pre-check: Target script exists
# =============================================================================
if [[ ! -f "$TARGET_SCRIPT" ]]; then
    log_fail "Target script not found: $TARGET_SCRIPT"
    exit 1
fi

# =============================================================================
# Test Group 1: Basic Checks
# =============================================================================
echo "--- Basic Checks ---"

run_test "File exists" "pass"

if [[ -x "$TARGET_SCRIPT" ]]; then
    run_test "Executable permission" "pass"
else
    log_info "Note: Run 'chmod +x $TARGET_SCRIPT' to make it executable"
    run_test "Executable permission" "fail"
fi

if bash -n "$TARGET_SCRIPT" 2>/dev/null; then
    run_test "Syntax check" "pass"
else
    run_test "Syntax check" "fail"
fi

SHEBANG=$(head -n 1 "$TARGET_SCRIPT")
if [[ "$SHEBANG" == "#!/bin/bash" || "$SHEBANG" == "#!/usr/bin/env bash" ]]; then
    run_test "Shebang is valid" "pass"
else
    run_test "Shebang is invalid: $SHEBANG" "fail"
fi

echo ""

# =============================================================================
# Test Group 2: Script Settings
# =============================================================================
echo "--- Script Settings ---"

if grep -q 'set -euo pipefail' "$TARGET_SCRIPT"; then
    run_test "Strict mode (set -euo pipefail)" "pass"
else
    run_test "Strict mode (set -euo pipefail)" "fail"
fi

if grep -q 'trap.*EXIT.*INT.*TERM.*QUIT.*HUP' "$TARGET_SCRIPT"; then
    run_test "Trap signals (EXIT, INT, TERM, QUIT, HUP)" "pass"
else
    run_test "Trap signals (EXIT, INT, TERM, QUIT, HUP)" "fail"
fi

echo ""

# =============================================================================
# Test Group 3: Required Functions
# =============================================================================
echo "--- Required Functions ---"

REQUIRED_FUNCTIONS=(
    "log_info"
    "log_success"
    "log_warning"
    "log_error"
    "error_exit"
    "check_command"
    "check_xcode"
    "check_interactive"
    "validate_dep"
    "get_brew_path"
    "format_step"
    "format_step"
    "init_logging"
    "parse_options"
    "show_help"
    "install_xcode"
    "install_homebrew"
    "install_via_brew"
    "install_prerequisites"
    "step_cleanup_symlinks"
    "backup_existing_chezmoi_config"
    "backup_existing_dotfiles"
    "handle_chezmoi_conflict"
    "step_apply_dotfiles"
    "step_install_cli_tools"
    "step_install_gui_apps"
    "step_finalize"
    "confirm_execution"
    "read_input"
    "main"
)

for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if grep -q "^${func}()" "$TARGET_SCRIPT"; then
        run_test "Function: $func" "pass"
    else
        run_test "Function: $func" "fail"
    fi
done

echo ""

# =============================================================================
# Test Group 4: Command-Line Options
# =============================================================================
echo "--- Command-Line Options ---"

if grep -q '\-\-no-log' "$TARGET_SCRIPT"; then
    run_test "Option: --no-log" "pass"
else
    run_test "Option: --no-log" "fail"
fi

if grep -q '\-\-no-color' "$TARGET_SCRIPT"; then
    run_test "Option: --no-color" "pass"
else
    run_test "Option: --no-color" "fail"
fi

if grep -q '\-\-non-interactive' "$TARGET_SCRIPT"; then
    run_test "Option: --non-interactive" "pass"
else
    run_test "Option: --non-interactive" "fail"
fi

if grep -q '\-\-help' "$TARGET_SCRIPT"; then
    run_test "Option: --help" "pass"
else
    run_test "Option: --help" "fail"
fi

echo ""

# =============================================================================
# Test Group 5: Architecture Support
# =============================================================================
echo "--- Architecture Support ---"

if grep -q '/opt/homebrew/bin/brew' "$TARGET_SCRIPT"; then
    run_test "Apple Silicon Homebrew path" "pass"
else
    run_test "Apple Silicon Homebrew path" "fail"
fi

if grep -q '/usr/local/bin/brew' "$TARGET_SCRIPT"; then
    run_test "Intel Mac Homebrew path" "pass"
else
    run_test "Intel Mac Homebrew path" "fail"
fi

echo ""

# =============================================================================
# Test Group 6: Security & Safety
# =============================================================================
echo "--- Security & Safety ---"

# Check for dependency validation using case statement (replaces ALLOWED_DEPS array)
if grep -q 'validate_dep()' "$TARGET_SCRIPT" && grep -A10 'validate_dep()' "$TARGET_SCRIPT" | grep -q 'case'; then
    run_test "Dependency validation (case statement)" "pass"
else
    run_test "Dependency validation (case statement)" "fail"
fi

if grep -A20 'install_homebrew()' "$TARGET_SCRIPT" | grep -q 'grep.*Homebrew'; then
    run_test "Homebrew installer validation" "pass"
else
    run_test "Homebrew installer validation" "fail"
fi

if grep -q 'backup_existing' "$TARGET_SCRIPT" && grep -q 'BACKUP_EXTENSION' "$TARGET_SCRIPT"; then
    run_test "Backup functionality" "pass"
else
    run_test "Backup functionality" "fail"
fi

if grep -q '>&2' "$TARGET_SCRIPT"; then
    run_test "Error output to stderr" "pass"
else
    run_test "Error output to stderr" "fail"
fi

echo ""

# =============================================================================
# Test Group 7: Constants & Configuration
# =============================================================================
echo "--- Constants & Configuration ---"

if grep -q 'SCRIPT_VERSION=' "$TARGET_SCRIPT"; then
    run_test "Script version constant" "pass"
else
    run_test "Script version constant" "fail"
fi

if grep -q 'CONFIG_MISE=' "$TARGET_SCRIPT" && grep -q 'CONFIG_BREWFILE=' "$TARGET_SCRIPT"; then
    run_test "Configuration file paths" "pass"
else
    run_test "Configuration file paths" "fail"
fi

if grep -q 'SCRIPT_CLEANUP_SYMLINKS=' "$TARGET_SCRIPT"; then
    run_test "Cleanup script path variable" "pass"
else
    run_test "Cleanup script path variable" "fail"
fi

if grep -q 'MAX_CONFLICT_RETRIES=' "$TARGET_SCRIPT"; then
    run_test "Conflict retry limit" "pass"
else
    run_test "Conflict retry limit" "fail"
fi

echo ""

# =============================================================================
# Test Group 8: Non-Interactive Mode
# =============================================================================
echo "--- Non-Interactive Mode ---"

if grep -q 'NON_INTERACTIVE=' "$TARGET_SCRIPT"; then
    run_test "NON_INTERACTIVE variable" "pass"
else
    run_test "NON_INTERACTIVE variable" "fail"
fi

if grep -A5 'check_interactive()' "$TARGET_SCRIPT" | grep -q 'NON_INTERACTIVE'; then
    run_test "Non-interactive in check_interactive" "pass"
else
    run_test "Non-interactive in check_interactive" "fail"
fi

if sed -n '/^confirm_execution()/,/^}/p' "$TARGET_SCRIPT" | grep -q 'NON_INTERACTIVE'; then
    run_test "Non-interactive in confirm_execution" "pass"
else
    run_test "Non-interactive in confirm_execution" "fail"
fi

if grep -A15 'handle_chezmoi_conflict()' "$TARGET_SCRIPT" | grep -q 'NON_INTERACTIVE'; then
    run_test "Non-interactive in handle_chezmoi_conflict" "pass"
else
    run_test "Non-interactive in handle_chezmoi_conflict" "fail"
fi

echo ""

# =============================================================================
# Test Group 9: TTY Handling
# =============================================================================
echo "--- TTY Handling ---"

if grep -q '^read_input()' "$TARGET_SCRIPT"; then
    run_test "read_input function" "pass"
else
    run_test "read_input function" "fail"
fi

if grep -A15 'read_input()' "$TARGET_SCRIPT" | grep -q '/dev/tty'; then
    run_test "/dev/tty fallback in read_input" "pass"
else
    run_test "/dev/tty fallback in read_input" "fail"
fi

if grep -q '\[ ! -t 0 \]' "$TARGET_SCRIPT"; then
    run_test "Interactive terminal check (-t 0)" "pass"
else
    run_test "Interactive terminal check (-t 0)" "fail"
fi

echo ""

# =============================================================================
# Test Group 10: Documentation
# =============================================================================
echo "--- Documentation ---"

if grep -q 'Dotfiles Setup Script' "$TARGET_SCRIPT"; then
    run_test "Script header documentation" "pass"
else
    run_test "Script header documentation" "fail"
fi

if grep -q '使用方法' "$TARGET_SCRIPT"; then
    run_test "Usage instructions" "pass"
else
    run_test "Usage instructions" "fail"
fi

if grep -q '依存関係' "$TARGET_SCRIPT"; then
    run_test "Dependencies documented" "pass"
else
    run_test "Dependencies documented" "fail"
fi

echo ""

# =============================================================================
# Test Group 11: chezmoi Configuration
# =============================================================================
echo "--- chezmoi Configuration ---"

ZSHRC_PATH="./.chezmoi/dot_zshrc"

if [[ -f "$ZSHRC_PATH" ]]; then
    run_test "dot_zshrc exists in chezmoi" "pass"
    
    if grep -q 'command -v mise' "$ZSHRC_PATH"; then
        run_test "mise support in dot_zshrc" "pass"
    else
        run_test "mise support in dot_zshrc" "fail"
    fi
else
    run_test "dot_zshrc exists in chezmoi" "skip"
    run_test "mise support in dot_zshrc" "skip"
fi

echo ""

# =============================================================================
# Test Group 12: Script Structure
# =============================================================================
echo "--- Script Structure ---"

LINES=$(wc -l < "$TARGET_SCRIPT")
if [[ "$LINES" -ge 500 ]]; then
    run_test "Script length: $LINES lines (>= 500)" "pass"
else
    run_test "Script length: $LINES lines (< 500)" "fail"
fi

if tail -n 20 "$TARGET_SCRIPT" | grep -q '^main()'; then
    run_test "main function defined" "pass"
else
    run_test "main function defined" "fail"
fi

if tail -n 5 "$TARGET_SCRIPT" | grep -q 'main'; then
    run_test "main called at end" "pass"
else
    run_test "main called at end" "fail"
fi

echo ""

# =============================================================================
# Summary
# =============================================================================
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo ""
echo "  Total:   $TOTAL_TESTS"
echo -e "  ${GREEN}Passed:  $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed:  $FAILED_TESTS${NC}"
echo -e "  ${YELLOW}Skipped: $SKIPPED_TESTS${NC}"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}[SUCCESS]${NC} All tests passed!"
    echo ""
    log_info "For automated tests with Bats, run: bash test_runner.sh"
    exit 0
else
    echo -e "${RED}[FAILED]${NC} Some tests failed. Please review the output above."
    exit 1
fi
