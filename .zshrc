# ==============================================================================
# 1. Path & Environment (Prezto読み込み前に必須)
# ==============================================================================
# Apple Silicon MacのHomebrewパスを最優先に設定
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# zsh-completions のパスを Prezto 起動前に追加
# これにより Prezto 内部の compinit がこのパスを認識します
if type brew &>/dev/null; then
  fpath=($(brew --prefix)/share/zsh-completions $fpath)
fi

# ==============================================================================
# 2. Powerlevel10k Instant Prompt
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# 3. Source Prezto
# ==============================================================================
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# ==============================================================================
# 4. Tool Initializations (Preztoの後に読み込む)
# ==============================================================================
# fzf の初期化 (Preztoにモジュールがないため、ここで直接読み込む)
if (( $+commands[fzf] )); then
  source <(fzf --zsh)
fi

# zoxide の初期化
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# zsh-autosuggestions の読み込み (最後の方に読み込むのが安定のコツ)
if type brew &>/dev/null; then
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ==============================================================================
# 5. Aliases & Custom Functions
# ==============================================================================
# eza: 標準のlsエイリアスを上書き
if (( $+commands[eza] )); then
  alias ls='eza --icons --git'
  alias ll='eza -alF --icons --git'
  alias la='eza -a --icons --git'
  alias lt='eza --tree --icons'
fi

# lb: ブランチ切り替え (fzfプレビュー付き)
alias -g lb='$(git branch --all | grep -v "HEAD" | fzf --prompt "GIT BRANCH> " --height 40% --reverse --info=inline --preview "git log --oneline --graph --color=always {1}" | sed -e "s/^\*\s*//g" | tr -d " ")'

# de: dockerコンテナに入る
alias de='docker exec -it $(docker ps | fzf --header-lines=1 --height 40% --reverse | awk "{print \$1}") /bin/bash'

# Ctrl+g: ghqリポジトリ一覧から選択して移動
function fzf-src () {
  local src=$(ghq list --full-path | fzf --query "$LBUFFER")
  if [ -n "$src" ]; then
    BUFFER="cd $src"
    zle accept-line
  fi
  zle -R
}
zle -N fzf-src
bindkey '^g' fzf-src

# ==============================================================================
# 6. Theme Config (Powerlevel10k)
# ==============================================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh