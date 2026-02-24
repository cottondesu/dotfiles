#!/bin/bash

set -euo pipefail

MANAGED_FILES=(".gitconfig" ".gitignore_global" ".zshrc" ".zpreztorc" ".p10k.zsh")

cleanup_from_chezmoi() {
    local file
    while IFS= read -r file; do
        # Skip empty lines
        [[ -z "$file" ]] && continue
        # chezmoi managed は相対パスを返すため $HOME/ を付加
        local target="$HOME/$file"
        if [[ -L "$target" ]]; then
            echo "管理対象のシンボリックリンクを削除: $target"
            rm -f "$target"
        fi
    done < <(chezmoi managed 2>/dev/null || true)
}

cleanup_from_list() {
    for file in "${MANAGED_FILES[@]}"; do
        local target="$HOME/$file"
        if [[ -L "$target" ]]; then
            echo "シンボリックリンクを削除: $target"
            rm -f "$target"
        fi
    done
}

if command -v chezmoi >/dev/null 2>&1; then
    if ! cleanup_from_chezmoi; then
        echo "警告: chezmoi managed クエリに失敗しました。静的リストにフォールバックします"
        cleanup_from_list
    fi
else
    cleanup_from_list
fi
