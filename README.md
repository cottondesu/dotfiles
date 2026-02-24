# Dotfiles

Macの環境構築を自動化するための設定ファイルとスクリプト集です。

## 概要

以下のツールを使用して環境構築を行います：

- **chezmoi**: dotfilesの管理
- **mise**: CLIツールの管理
- **Homebrew**: GUIアプリ（cask）の管理

## セットアップ手順

ターミナルでこのディレクトリに移動し、以下のコマンドを順に実行してください。

### 1. リポジトリのクローン

```bash
git clone https://github.com/horykai/dotfiles.git
cd dotfiles
```

### 2. セットアップの実行

以下のコマンドを実行すると、dotfilesの適用、CLIツールのインストール、GUIアプリのインストールを一括で行います。

```bash
bash install.sh
```

#### オプション

| オプション | 説明 |
| --- | --- |
| `--no-log` | ログファイルを作成しません |
| `--no-color` | カラー出力を無効にします（CI環境などで便利） |
| `--non-interactive`, `-y` | 非対話モード（確認をスキップ） |
| `--help`, `-h` | ヘルプを表示 |

例：
```bash
# ログ無効で実行
bash install.sh --no-log

# 非対話モード（環境変数でemail/nameを指定）
CHEZMOI_EMAIL="your@email.com" CHEZMOI_NAME="Your Name" bash install.sh --non-interactive

# 複数オプションの組み合わせ
bash install.sh --no-log --no-color

# CIモード
bash install.sh --no-log --no-color -y
```

※ 完了まで時間がかかります。

### セットアップの流れ

`install.sh` は以下のステップを順に実行します：

1. **前提ツールのインストール** — Xcode Command Line Tools, Homebrew, chezmoi, mise
2. **古いシンボリックリンクの削除** — `cleanup_symlinks.sh` を実行
3. **dotfilesの適用** — chezmoi でホームディレクトリに設定ファイルを展開
4. **CLIツールのインストール** — mise で `mise.toml` に定義されたツールをインストール
5. **GUIアプリのインストール** — Homebrew で `Brewfile` に定義されたアプリをインストール
6. **セットアップ完了**

## テスト

スクリプトの変更を検証するためのテストスイートが用意されています。

### テストの実行

Bats (Bash Automated Testing System) が必要です。

```bash
# Batsのインストール（miseで管理している場合は不要）
brew install bats-core

# テストの実行
bash test_runner.sh
```

または直接実行：

```bash
# すべてのテストを実行
bats tests/test_*.bats

# 特定のテストファイルを実行
bats tests/test_install.bats

# 詳細な出力
bats -t tests/test_install.bats
```

### テストの種類

| テストカテゴリ | 説明 |
| --- | --- |
| 構文チェック | スクリプトのシンタックス検証 |
| 関数単体テスト | ログ関数、コマンドチェック関数など |
| オプション解析 | `--no-log`、`--no-color` オプションの動作 |
| パス設定 | Apple Silicon/Intel Mac の Homebrew パス |
| エラーハンドリング | エラー出力、セットの検証 |
| ドキュメント | スクリプトのドキュメントが含まれているか |

### 手動テスト

`manual_test.sh` を使用して、インタラクティブな動作確認を行うこともできます。

```bash
bash manual_test.sh
```

## ファイル構成

```
dotfiles/
├── .chezmoi/                          # chezmoi ソースディレクトリ
│   ├── .chezmoiexternal.toml          #   外部リポジトリ定義（Prezto, Powerlevel10k）
│   ├── dot_gitconfig.tmpl             #   Git設定ファイルテンプレート
│   ├── dot_gitignore_global           #   Gitのグローバル除外設定
│   ├── dot_p10k.zsh                   #   Powerlevel10k設定ファイル
│   ├── dot_zpreztorc                  #   Prezto設定ファイル
│   └── dot_zshrc                      #   Zsh設定ファイル
├── .chezmoiscripts/                   # chezmoi スクリプト
│   └── run_once_setup_prezto_runcoms.sh  Prezto runcoms設定スクリプト
├── .chezmoi.toml.tmpl                 # chezmoi設定テンプレート（email/name入力）
├── .chezmoiignore                     # chezmoi管理対象外ファイル定義
├── .gitignore                         # Git除外設定
├── Brewfile                           # GUIアプリ定義（Homebrew cask）
├── mise.toml                          # CLIツール定義（mise）
├── install.sh                         # セットアップ一括実行スクリプト
├── cleanup_symlinks.sh                # 古いシンボリックリンク削除スクリプト
├── test_runner.sh                     # テストランナー
├── manual_test.sh                     # 手動テストスクリプト
├── tests/                             # テストスイート
│   ├── test_install.bats              #   install.sh のユニットテスト
│   └── README.md                      #   テストドキュメント
└── README.md                          # このファイル
```

## インストールされる主要ツールの使い方

### CLIツール（mise.toml で管理）

#### eza (lsの代替)

```bash
# 基本的な使用方法
eza

# 詳細表示（ls -la相当）
eza -la

# ツリー表示
eza --tree
```

#### fzf (あいまい検索)

```bash
# コマンド履歴からの検索 (Ctrl + R)
# ファイル検索 (Ctrl + T)
# ディレクトリ移動 (Alt + C)
```

#### gh (GitHub CLI)

```bash
# リポジトリの作成
gh repo create

# プルリクエストの作成
gh pr create

# イシューの閲覧
gh issue list
```

#### ghq (リポジトリ管理)

```bash
# リポジトリの取得
ghq get <repository-url>

# 管理下のリポジトリ一覧
ghq list
```

#### lazygit (Git TUI)

```bash
# 基本的な起動
lazygit

# カレントディレクトリのリポジトリを操作
# キーボードショートカットでステージング、コミット、プッシュなどが可能
```

#### zoxide (cdの代替)

```bash
# ディレクトリへの移動（履歴から推測）
z <directory-name>

# インタラクティブな選択
zi
```

### GUIアプリ（Brewfile で管理）

`Brewfile` に定義されたアプリが `brew bundle` でインストールされます。
主なアプリ：1Password, Cursor, Ghostty, Google Chrome, Raycast, Slack, Docker Desktop など。

## トラブルシューティング

### chezmoiコンフリクトエラー

**症状**: `bash install.sh` 実行時に以下のエラーが表示される

```
.zpreztorc has changed since chezmoi last wrote it?
```

**原因**: 既存の設定ファイルとchezmoi管理版の間でコンフリクトが発生

**解決方法**:

```bash
# 1. 差分を確認
chezmoi diff .zpreztorc

# 2. オプションを選択
#    1) chezmoi管理版を使用 (--force)
#    2) 既存ファイルを維持
#    3) 差分を確認してマニュアルマージ

# 3. 強制的に適用する場合
chezmoi apply --force
```

### 既存環境でのセットアップ

既にdotfilesを管理している環境でセットアップする場合:

1. 既存の設定ファイルは自動的にバックアップされます
2. `.zshrc.YYYYMMDD_HHMMSS.backup` のような形式で保存
3. 必要に応じて手動でマージしてください

### 外部リポジトリのクローンに失敗

**症状**: PreztoまたはPowerlevel10kのクローンに失敗

**原因**: `.chezmoi/.chezmoiexternal.toml` が見つからない、またはネットワークエラー

**解決方法**:

```bash
# 手動で外部リポジトリをクローン
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
```

### シンボリックリンクの問題

**症状**: 設定ファイルが正しく反映されない

**原因**: 古いシンボリックリンクが残っている

**解決方法**:

```bash
# cleanup_symlinks.shを実行
bash cleanup_symlinks.sh

# 手動で削除する場合
find ~ -maxdepth 1 -type l -name ".*" | xargs rm
```

### テストが失敗する

**症状**: `bash test_runner.sh` 実行時にエラー

**解決方法**:

```bash
# Batsをインストール
brew install bats-core

# プロジェクトルートで実行
bash test_runner.sh
```

### Powerlevel10kが表示されない

**症状**: プロンプトがデフォルトのまま

**原因**: Powerlevel10kの設定が適用されていない

**解決方法**:

```bash
# 設定ウィザードを再実行
p10k configure

# または手動で設定を再読み込み
source ~/.p10k.zsh
```
