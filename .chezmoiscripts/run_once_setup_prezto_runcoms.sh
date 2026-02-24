#!/bin/zsh
# =============================================================================
# Prezto Runcoms Setup Script
# =============================================================================
# このスクリプトはchezmoi apply後に一度だけ実行され、Preztoのruncomsシンボリックリンクを作成します。
# Powerlevel10kは.chezmoiexternal.tomlで管理されるため、ここではシンボリックリンクを作成しません。
# =============================================================================

set -e
setopt EXTENDED_GLOB

echo "[Prezto Setup] Prezto runcomsのシンボリックリンクを作成しています..."


zprezto_dir="${ZDOTDIR:-$HOME}/.zprezto"
if [[ ! -d "$zprezto_dir" ]]; then
    echo "[Prezto Setup] エラー: Preztoディレクトリが見つかりません: $zprezto_dir" >&2
    exit 1
fi

# Create Prezto runcoms symlinks
for rcfile in ${zprezto_dir}/runcoms/^README.md(.N); do
    target="${ZDOTDIR:-$HOME}/.${rcfile:t}"
    if [[ ! -e "$target" ]]; then
        ln -s "$rcfile" "$target"
        echo "[Prezto Setup] 作成: $target -> $rcfile"
    else
        echo "[Prezto Setup] スキップ: $target (既に存在)"
    fi
done

echo "[Prezto Setup] 完了"
