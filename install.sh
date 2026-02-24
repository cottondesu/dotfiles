#!/bin/bash
# =============================================================================
# Dotfiles Setup Script
# =============================================================================
#
# macOSの環境構築を自動化するスクリプト
#
# 使用方法:
#   bash install.sh [オプション]
#
# オプション:
#   --no-log          ログファイルを作成しない
#   --no-color        カラー出力を無効化（CI環境向け）
#   --non-interactive 非対話モード（確認をスキップ）
#   -y                --non-interactiveの短縮形
#   --help, -h        ヘルプを表示
#
# 依存関係:
#   - bash 3.2以上
#   - macOS 10.15以上
#   - インターネット接続
#
# 環境変数:
#   CHEZMOI_EMAIL  chezmoi設定用メールアドレス（非対話モード時必須）
#   CHEZMOI_NAME   chezmoi設定用ユーザー名（非対話モード時必須）
#
# =============================================================================

set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Configuration files
readonly CONFIG_MISE="${SCRIPT_DIR}/mise.toml"
readonly CONFIG_BREWFILE="${SCRIPT_DIR}/Brewfile"
readonly SCRIPT_CLEANUP_SYMLINKS="${SCRIPT_DIR}/cleanup_symlinks.sh"

# Backup settings
readonly BACKUP_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_EXTENSION="${BACKUP_TIMESTAMP}.backup"

# Limits
readonly MAX_CONFLICT_RETRIES=3
readonly TOTAL_STEPS=5

# Homebrew paths
readonly BREW_PATH_APPLE_SILICON="/opt/homebrew/bin/brew"
readonly BREW_PATH_INTEL="/usr/local/bin/brew"

# =============================================================================
# Global Variables
# =============================================================================

LOG_ENABLED="true"
LOG_FILE=""
COLOR_ENABLED="true"
NON_INTERACTIVE="false"
TEMP_FILES=()
CACHED_BREW_PATH=""

# Color codes (will be disabled if COLOR_ENABLED=false)
RED=""
GREEN=""
YELLOW=""
BLUE=""
BOLD=""
NC=""

# =============================================================================
# Cleanup Handler
# =============================================================================

cleanup_temp_files() {
    # Guard against unset array with default empty
    local files=("${TEMP_FILES[@]+${TEMP_FILES[@]}}")
    [[ ${#files[@]} -eq 0 ]] && return 0
    local tmp_file
    for tmp_file in "${files[@]}"; do
        [[ -f "$tmp_file" ]] && rm -f "$tmp_file"
    done
}

trap cleanup_temp_files EXIT INT TERM QUIT HUP

# =============================================================================
# Color Setup
# =============================================================================

setup_colors() {
    if [[ "$COLOR_ENABLED" == "true" ]] && [[ -t 1 ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        BOLD='\033[1m'
        NC='\033[0m'
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        BOLD=""
        NC=""
    fi
}

# =============================================================================
# Logging Functions
# =============================================================================

init_logging() {
    if [[ "$LOG_ENABLED" == "true" ]]; then
        LOG_FILE="${SCRIPT_DIR}/dotfiles_setup_${BACKUP_TIMESTAMP}_$$.log"
        touch "$LOG_FILE" 2>/dev/null || LOG_ENABLED="false"
    fi
}

log_to_file() {
    [[ "$LOG_ENABLED" != "true" || -z "$LOG_FILE" ]] && return 0
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} ${message}"
    log_to_file "INFO: ${message}"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} ${message}"
    log_to_file "SUCCESS: ${message}"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} ${message}"
    log_to_file "WARNING: ${message}"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} ${message}" >&2
    log_to_file "ERROR: ${message}"
}

error_exit() {
    local message="$1"
    local code="${2:-1}"
    log_error "$message"
    exit "$code"
}

# =============================================================================
# Utility Functions
# =============================================================================

check_command() {
    command -v "$1" >/dev/null 2>&1
}

check_xcode() {
    xcode-select -p >/dev/null 2>&1
}

check_interactive() {
    [[ "$NON_INTERACTIVE" == "true" ]] && return 0
    [[ -t 0 ]] && return 0
    return 1
}

# Validate dependency name against allowlist (security measure)
# NOTE: Currently unused but kept for future use in install_prerequisites
validate_dep() {
    local dep="$1"
    # O(1) lookup using case statement
    case "$dep" in
        homebrew|chezmoi|mise|git|curl|xcode-select)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

get_brew_path() {
    if [[ -n "$CACHED_BREW_PATH" ]]; then
        echo "$CACHED_BREW_PATH"
        return 0
    fi

    local brew_path=""
    if [[ -f "$BREW_PATH_APPLE_SILICON" ]]; then
        brew_path="$BREW_PATH_APPLE_SILICON"
    elif [[ -f "$BREW_PATH_INTEL" ]]; then
        brew_path="$BREW_PATH_INTEL"
    fi

    if [[ -n "$brew_path" ]]; then
        CACHED_BREW_PATH="$brew_path"
        echo "$brew_path"
        return 0
    fi

    return 1
}

format_step() {
    printf '[%d/%d]' "$1" "$TOTAL_STEPS"
}

read_input() {
    local prompt="$1"
    local var_name="$2"
    local input=""
    
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        printf -v "$var_name" '%s' ""
        return 0
    fi
    
    if [[ -t 0 ]]; then
        read -r -p "$prompt" input
    elif [[ -e /dev/tty ]]; then
        read -r -p "$prompt" input < /dev/tty
    fi
    
    # Use printf -v for safe variable assignment (Bash 3.1+)
    printf -v "$var_name" '%s' "$input"
}

# =============================================================================
# Option Parsing
# =============================================================================

show_help() {
    cat << EOF
Dotfiles Setup Script v${SCRIPT_VERSION}

使用方法:
  ${SCRIPT_NAME} [オプション]

オプション:
  --no-log          ログファイルを作成しない
  --no-color        カラー出力を無効化
  --non-interactive 非対話モード（確認をスキップ）
  -y                --non-interactiveの短縮形
  --help, -h        このヘルプを表示

環境変数:
  CHEZMOI_EMAIL     chezmoi設定用メールアドレス
  CHEZMOI_NAME      chezmoi設定用ユーザー名

例:
  # 通常実行
  bash ${SCRIPT_NAME}

  # 非対話モード
  CHEZMOI_EMAIL="you@example.com" CHEZMOI_NAME="Your Name" \\
    bash ${SCRIPT_NAME} --non-interactive

  # CIモード
  bash ${SCRIPT_NAME} --no-log --no-color -y
EOF
    exit 0
}

parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-log)
                LOG_ENABLED="false"
                shift
                ;;
            --no-color)
                COLOR_ENABLED="false"
                shift
                ;;
            --non-interactive|-y)
                NON_INTERACTIVE="true"
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
}

# =============================================================================
# Installation Functions
# =============================================================================

install_xcode() {
    log_info "Checking Xcode Command Line Tools..."
    
    if check_xcode; then
        log_success "Xcode Command Line Tools already installed"
        return 0
    fi
    
    log_info "Installing Xcode Command Line Tools..."
    xcode-select --install 2>/dev/null || true
    
    # Wait for installation
    local max_wait=300
    local waited=0
    while ! check_xcode && [[ $waited -lt $max_wait ]]; do
        sleep 5
        waited=$((waited + 5))
        log_info "Waiting for Xcode installation... (${waited}s)"
    done
    
    if check_xcode; then
        log_success "Xcode Command Line Tools installed"
    else
        error_exit "Xcode Command Line Tools installation timed out"
    fi
}

install_homebrew() {
    log_info "Checking Homebrew..."
    
    if check_command brew; then
        log_success "Homebrew already installed"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    
    # Download installer
    local brew_installer
    brew_installer=$(mktemp "/tmp/brew_install_$$.XXXXXXXX.sh")
    TEMP_FILES+=("$brew_installer")
    
    curl -fsSL --connect-timeout 30 --max-time 120 https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$brew_installer"
    
    # Validate installer
    if ! grep -q "Homebrew" "$brew_installer"; then
        error_exit "Downloaded Homebrew installer appears invalid"
    fi
    
    # Run installer
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        NONINTERACTIVE=1 /bin/bash "$brew_installer"
    else
        /bin/bash "$brew_installer"
    fi
    
    # Setup PATH
    local brew_path
    if brew_path=$(get_brew_path); then
        eval "$("$brew_path" shellenv)"
        log_success "Homebrew installed and configured"
    else
        error_exit "Homebrew installation failed"
    fi
}

install_via_brew() {
    local formula="$1"
    local brew_path
    
    if ! brew_path=$(get_brew_path); then
        error_exit "Homebrew not found"
    fi
    
    if "$brew_path" list "$formula" &>/dev/null; then
        log_info "$formula already installed"
        return 0
    fi
    
    log_info "Installing $formula..."
    "$brew_path" install "$formula"
    log_success "$formula installed"
}

install_prerequisites() {
    log_info "Installing prerequisites..."
    
    install_xcode
    install_homebrew
    install_via_brew "chezmoi"
    install_via_brew "mise"
    
    log_success "All prerequisites installed"
}

# =============================================================================
# Step Functions
# =============================================================================

step_cleanup_symlinks() {
    local step_num="$1"
    log_info "$(format_step "$step_num") Cleaning up old symlinks..."
    
    if [[ -f "$SCRIPT_CLEANUP_SYMLINKS" ]]; then
        bash "$SCRIPT_CLEANUP_SYMLINKS"
        log_success "Old symlinks cleaned up"
    else
        log_warning "cleanup_symlinks.sh not found, skipping..."
    fi
}

backup_existing_chezmoi_config() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
    local config_file="$config_dir/chezmoi.toml"
    
    if [[ -f "$config_file" ]]; then
        local backup_path="${config_file}.${BACKUP_EXTENSION}"
        cp "$config_file" "$backup_path"
        log_info "Backed up chezmoi config: $backup_path"
    fi
}

backup_existing_dotfiles() {
    log_info "Backing up existing dotfiles..."
    
    local dotfiles=(".zshrc" ".zpreztorc" ".gitconfig" ".p10k.zsh")
    local file
    
    for file in "${dotfiles[@]}"; do
        local filepath="$HOME/$file"
        if [[ -f "$filepath" ]] && [[ ! -L "$filepath" ]]; then
            local backup_path="${filepath}.${BACKUP_EXTENSION}"
            cp "$filepath" "$backup_path"
            log_info "Backed up: $file -> ${file}.${BACKUP_EXTENSION}"
        fi
    done
}

handle_chezmoi_conflict() {
    local retries=0
    local apply_output
    
    while [[ $retries -lt $MAX_CONFLICT_RETRIES ]]; do
        # Capture output to check for conflicts without losing exit status
        apply_output=$(chezmoi apply 2>&1) || true
        
        if echo "$apply_output" | grep -q "has changed"; then
            retries=$((retries + 1))
            log_warning "Chezmoi conflict detected (attempt $retries/$MAX_CONFLICT_RETRIES)"
            
            if [[ "$NON_INTERACTIVE" == "true" ]]; then
                chezmoi apply --force
                return 0
            fi
            
            local choice=""
            echo "Conflict detected. Options:"
            echo "  1) Force apply (overwrite local changes)"
            echo "  2) Skip this file"
            echo "  3) Abort"
            read_input "Choose [1-3]: " choice
            
            case "$choice" in
                1) chezmoi apply --force; return 0 ;;
                2) return 0 ;;
                3) error_exit "Aborted by user" ;;
                *) log_warning "Invalid choice, retrying..." ;;
            esac
        else
            return 0
        fi
    done
    
    error_exit "Max conflict retries exceeded"
}

step_apply_dotfiles() {
    local step_num="$1"
    log_info "$(format_step "$step_num") Applying dotfiles with chezmoi..."
    
    backup_existing_chezmoi_config
    backup_existing_dotfiles
    
    # Initialize chezmoi - get source directory
    local chezmoi_source_dir
    if check_command chezmoi; then
        chezmoi_source_dir="$(chezmoi source-path 2>/dev/null)" || chezmoi_source_dir=""
    fi
    
    # Fallback to default location
    if [[ -z "$chezmoi_source_dir" ]]; then
        chezmoi_source_dir="${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi"
    fi
    
    mkdir -p "$chezmoi_source_dir"
    
    # Copy chezmoi files (use rsync-like approach for hidden files)
    if [[ -d "${SCRIPT_DIR}/.chezmoi" ]]; then
        # Copy all files including hidden ones
        (cd "${SCRIPT_DIR}/.chezmoi" && find . -maxdepth 1 -mindepth 1 -exec cp -R {} "$chezmoi_source_dir/" \;)
    fi
    
    # Copy chezmoi config template
    if [[ -f "${SCRIPT_DIR}/.chezmoi.toml.tmpl" ]]; then
        cp "${SCRIPT_DIR}/.chezmoi.toml.tmpl" "$chezmoi_source_dir/"
    fi
    
    # Copy chezmoi scripts (including hidden files)
    if [[ -d "${SCRIPT_DIR}/.chezmoiscripts" ]]; then
        (cd "${SCRIPT_DIR}/.chezmoiscripts" && find . -maxdepth 1 -mindepth 1 -exec cp -R {} "$chezmoi_source_dir/" \;) 2>/dev/null || true
    fi
    
    # Apply with conflict handling
    handle_chezmoi_conflict
    
    log_success "Dotfiles applied"
}

step_install_cli_tools() {
    local step_num="$1"
    log_info "$(format_step "$step_num") Installing CLI tools with mise..."
    
    if [[ ! -f "$CONFIG_MISE" ]]; then
        log_warning "mise.toml not found, skipping CLI tools..."
        return 0
    fi
    
    # Activate mise
    local brew_path
    if brew_path=$(get_brew_path); then
        eval "$("$brew_path" shellenv)"
    fi
    
    if check_command mise; then
        mise install --yes
        log_success "CLI tools installed"
    else
        log_warning "mise not found, skipping CLI tools..."
    fi
}

step_install_gui_apps() {
    local step_num="$1"
    log_info "$(format_step "$step_num") Installing GUI apps with Homebrew..."
    
    if [[ ! -f "$CONFIG_BREWFILE" ]]; then
        log_warning "Brewfile not found, skipping GUI apps..."
        return 0
    fi
    
    local brew_path
    if ! brew_path=$(get_brew_path); then
        error_exit "Homebrew not found"
    fi
    
    "$brew_path" bundle install --file="$CONFIG_BREWFILE"
    
    log_success "GUI apps installed"
}

step_finalize() {
    local step_num="$1"
    log_info "$(format_step "$step_num") Finalizing setup..."
    
    # Source new shell config
    if [[ -f "$HOME/.zshrc" ]]; then
        log_info "Shell configuration updated"
    fi
    
    log_success "Setup complete!"
    
    if [[ "$LOG_ENABLED" == "true" ]] && [[ -n "$LOG_FILE" ]]; then
        log_info "Log file: $LOG_FILE"
    fi
    
    echo ""
    echo "=========================================="
    echo "  Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Please restart your terminal or run:"
    echo "  exec zsh -l"
    echo ""
}

# =============================================================================
# Confirmation
# =============================================================================

confirm_execution() {
    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        log_info "Running in non-interactive mode"
        return 0
    fi
    
    if [[ ! -t 0 ]]; then
        log_warning "Not running in interactive terminal"
        return 0
    fi
    
    echo ""
    echo "=========================================="
    echo "  Dotfiles Setup Script v${SCRIPT_VERSION}"
    echo "=========================================="
    echo ""
    echo "This script will:"
    echo "  1. Clean up old symlinks"
    echo "  2. Apply dotfiles with chezmoi"
    echo "  3. Install CLI tools with mise"
    echo "  4. Install GUI apps with Homebrew"
    echo "  5. Finalize setup"
    echo ""
    
    local response=""
    read_input "Continue? [y/N]: " response
    
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            error_exit "Aborted by user"
            ;;
    esac
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    parse_options "$@"
    setup_colors
    init_logging
    log_info "Dotfiles Setup Script v${SCRIPT_VERSION}"
    log_info "Script directory: ${SCRIPT_DIR}"
    confirm_execution
    install_prerequisites
    step_cleanup_symlinks 1
    step_apply_dotfiles 2
    step_install_cli_tools 3
    step_install_gui_apps 4
    step_finalize 5
}

main "$@"
