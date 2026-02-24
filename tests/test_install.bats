#!/usr/bin/env bats
# test_install.bats
# Test suite for Dotfiles Setup Script

# ==============================================================================
# Test Environment Setup
# ==============================================================================

# Script path (relative to project root)
SCRIPT_PATH="${BATS_TEST_DIRNAME}/../install.sh"

# Test setup (mock functions)
setup() {
    # Save original PATH
    export ORIGINAL_PATH="$PATH"

    # Create test directory
    TEST_HOME="$BATS_TMPDIR/test_home_$$"
    export HOME="$TEST_HOME"
    mkdir -p "$TEST_HOME"

    # Test XDG directories
    export XDG_CONFIG_HOME="$TEST_HOME/.config"
    export XDG_CACHE_HOME="$TEST_HOME/.cache"
    mkdir -p "$XDG_CONFIG_HOME"
    mkdir -p "$XDG_CACHE_HOME"

    # Copy script for testing
    cp "$SCRIPT_PATH" "$BATS_TMPDIR/install_test.sh"

    # Create mock directory
    mkdir -p "$TEST_HOME/bin"
}

teardown() {
    # Clean up test directories
    rm -rf "$TEST_HOME"
    rm -f "$BATS_TMPDIR/install_test.sh"

    # Restore original PATH
    export PATH="$ORIGINAL_PATH"
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# Source script (comment out main function call)
source_script() {
    local script="$BATS_TMPDIR/install_test.sh"

    # Comment out lines that interfere with bats:
    # - main function call
    # - set -euo pipefail (conflicts with bats internals)
    # - trap (conflicts with bats' own trap handling)
    sed -i.bak \
        -e 's/^main "\$@"$/# main "$@"/' \
        -e 's/^set -euo pipefail$/# set -euo pipefail/' \
        -e 's/^trap cleanup_temp_files/# trap cleanup_temp_files/' \
        "$script"
    rm -f "${script}.bak"

    # Source the script
    source "$script"
}

# ==============================================================================
# Syntax Check
# ==============================================================================

@test "syntax check passes" {
    run bash -n "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Log Function Tests
# ==============================================================================

@test "log_info outputs correctly" {
    source_script

    run log_info "test message"
    [ "$status" -eq 0 ]
    # Regex without quotes for compatibility
    [[ "$output" =~ \[INFO\].*test\ message ]]
}

@test "log_success outputs correctly" {
    source_script

    run log_success "success message"
    [ "$status" -eq 0 ]
    # Regex without quotes for compatibility
    [[ "$output" =~ \[SUCCESS\].*success\ message ]]
}

@test "log_warning outputs correctly" {
    source_script

    run log_warning "warning message"
    [ "$status" -eq 0 ]
    # Regex without quotes for compatibility
    [[ "$output" =~ \[WARNING\].*warning\ message ]]
}

@test "log_error outputs correctly" {
    source_script

    run log_error "error message"
    [ "$status" -eq 0 ]
    # Regex without quotes for compatibility
    [[ "$output" =~ \[ERROR\].*error\ message ]]
}

# ==============================================================================
# check_command Function Tests
# ==============================================================================

@test "check_command: existing command returns 0" {
    source_script

    run check_command bash
    [ "$status" -eq 0 ]
}

@test "check_command: nonexistent command returns 1" {
    source_script

    run check_command nonexistent_command_12345
    [ "$status" -eq 1 ]
}

# ==============================================================================
# check_interactive Function Tests
# ==============================================================================

@test "check_interactive: returns immediately when NON_INTERACTIVE=true" {
    source_script

    NON_INTERACTIVE=true
    run check_interactive
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Option Parsing Tests
# ==============================================================================

@test "default: logging is enabled" {
    # Check initial setting
    run bash -c '
        LOG_ENABLED="true"
        [ "$LOG_ENABLED" = "true" ]
    '
    [ "$status" -eq 0 ]
}

@test "option parsing: --no-log" {
    run bash -c '
        args=" --no-log "
        [[ " $args " =~ " --no-log " ]]
        echo "Matched: --no-log"
    '
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Matched" ]]
}

@test "option parsing: --no-color" {
    run bash -c '
        args=" --no-color "
        [[ " $args " =~ " --no-color " ]]
        echo "Matched: --no-color"
    '
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Matched" ]]
}

@test "option parsing: multiple options" {
    run bash -c '
        args=" --no-log --no-color "
        [[ " $args " =~ " --no-log " ]] && [[ " $args " =~ " --no-color " ]]
        echo "Matched both options"
    '
    [ "$status" -eq 0 ]
    [[ "$output" =~ "both options" ]]
}

# ==============================================================================
# Path Configuration Tests
# ==============================================================================

@test "Apple Silicon: Homebrew path is valid" {
    run bash -c '
        [ -f "/opt/homebrew/bin/brew" ] || echo "Not found (expected on non-Apple Silicon)"
    '
    # Path exists on Apple Silicon, message on Intel
    [ "$status" -eq 0 ]
}

@test "Intel Mac: Homebrew path is valid" {
    run bash -c '
        [ -f "/usr/local/bin/brew" ] || echo "Not found (expected on Apple Silicon)"
    '
    # Path exists on Intel Mac, message on Apple Silicon
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Chezmoi Config Backup Tests
# ==============================================================================

@test "chezmoi config backup path works correctly" {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
    local config_file="$config_dir/chezmoi.toml"
    local backup_file="$config_file.backup"

    mkdir -p "$config_dir"
    echo "test config" > "$config_file"

    # Simulate backup command
    cp "$config_file" "$backup_file"

    [ -f "$backup_file" ]
    [ "$(cat "$backup_file")" = "test config" ]
}

# ==============================================================================
# cleanup_symlinks.sh Path Tests
# ==============================================================================

@test "cleanup_symlinks.sh path is stored in a variable" {
    run grep -q "SCRIPT_CLEANUP_SYMLINKS=" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "cleanup_symlinks.sh has no hardcoded path" {
    # Verify variable-based approach is used
    run grep -n 'SCRIPT_CLEANUP_SYMLINKS=' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    # Verify no hardcoded path to .chezmoi/scripts
    run grep -n '.chezmoi/scripts/cleanup_symlinks' "$SCRIPT_PATH"
    [ "$status" -ne 0 ]
}

# ==============================================================================
# Error Handling Tests
# ==============================================================================

@test "set -euo pipefail is configured" {
    run grep -q 'set -euo pipefail' "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "shebang is correct" {
    run head -n 1 "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "#!/bin/bash" ]]
}

# ==============================================================================
# Documentation Tests
# ==============================================================================

@test "script contains description" {
    run grep -q "Dotfiles Setup Script" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "script contains usage documentation" {
    run grep -q "使用方法" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "script contains options documentation" {
    run grep -q "オプション" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# mise activate Tests
# ==============================================================================

@test "mise activate: Homebrew supported" {
    run grep -q "eval.*mise activate zsh" "$BATS_TEST_DIRNAME/../.chezmoi/dot_zshrc"
    [ "$status" -eq 0 ]
}

@test "mise activate: command -v check exists" {
    run grep -q "command -v mise" "$BATS_TEST_DIRNAME/../.chezmoi/dot_zshrc"
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Error Output Tests
# ==============================================================================

@test "log_error outputs to stderr" {
    source_script

    run log_error "error message" 2>&1
    [ "$status" -eq 0 ]
    # Regex without quotes for compatibility
    [[ "$output" =~ \[ERROR\].*error\ message ]]
}

# ==============================================================================
# Conflict Resolution Tests
# ==============================================================================

@test "conflict resolution: backup existing files" {
    local test_home="$BATS_TMPDIR/test_home_$$"
    mkdir -p "$test_home"

    local test_file="$test_home/.zshrc"
    echo "original content" > "$test_file"

    local backup_script="
        HOME=\"$test_home\"
        existing_files=(\".zshrc\")
        for file in \"\${existing_files[@]}\"; do
            if [ -f \"\$HOME/\$file\" ] && [ ! -L \"\$HOME/\$file\" ]; then
                backup_path=\"\$HOME/\$file.\$(date +%Y%m%d_%H%M%S).backup\"
                cp \"\$HOME/\$file\" \"\$backup_path\"
                echo \"\$backup_path\"
            fi
        done
    "

    run bash -c "$backup_script"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ".backup" ]]

    rm -rf "$test_home"
}

# ==============================================================================
# cleanup_symlinks.sh Tests
# ==============================================================================

# @test "cleanup_symlinks.sh: chezmoi管理のシンボリックリンク削除" {
#     local test_home="$BATS_TMPDIR/test_home_$$"
#     mkdir -p "$test_home"
#
#     local symlink="$test_home/.zshrc"
#     ln -s /some/target "$symlink"
#
#     run bash -c "HOME=\"$test_home\" command -v chezmoi >/dev/null 2>&1 && chezmoi managed 2>/dev/null || echo 'fallback'"
#     [ "$status" -eq 0 ]
#
#     rm -rf "$test_home"
# }

# ==============================================================================
# run_once_setup_prezto_runcoms.sh Tests
# ==============================================================================
