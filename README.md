# Dotfiles

Macの環境構築を自動化するための設定ファイルとスクリプト集です。

## 概要

以下の手順で、シンボリックリンクの作成からアプリケーションのインストールまでを一括で行います。

- **.Brewfile**: インストールするアプリケーション（Homebrew, Cask, Mac App Store）の定義
- **install.sh**: dotfiles（設定ファイル）のシンボリックリンク作成
- **homebrew_install.sh**: Homebrew のインストールと `.Brewfile` に基づくアプリ一括インストール

## セットアップ手順

ターミナルでこのディレクトリに移動し、以下のコマンドを順に実行してください。

### 1. リポジトリのクローン

```bash
git clone https://github.com/horykai/dotfiles.git
cd dotfiles
```

### 2. セットアップの実行

以下のコマンドを実行すると、シンボリックリンクの作成、Preztoのセットアップ、アプリケーションのインストールを一括で行います。

```bash
sh install.sh
```

※ Homebrew のインストール時にパスワード入力が求められる場合があります。
※ 完了まで時間がかかります。

## ファイル構成

| ファイル名 | 説明 |
| --- | --- |
| `.Brewfile` | インストール対象のパッケージ・アプリ一覧 |
| `.gitconfig` | Git設定ファイル（共通設定） |
| `.gitignore_global` | Gitのグローバル除外設定 |
| `.zshrc` | Zsh設定ファイル（Prezto読み込み用） |
| `install.sh` | **セットアップ一括実行スクリプト** |
| `setup_links.sh` | シンボリックリンク作成用スクリプト |
| `setup_prezto.zsh` | Preztoインストール用スクリプト |
| `homebrew_install.sh` | 環境構築実行用スクリプト |

## インストールされる主要ツールの使い方

### eza (lsの代替)

```bash
# 基本的な使用方法
eza

# 詳細表示（ls -la相当）
eza -la

# ツリー表示
eza --tree
```

### fzf (あいまい検索)

```bash
# コマンド履歴からの検索 (Ctrl + R)
# ファイル検索 (Ctrl + T)
# ディレクトリ移動 (Alt + C)
```

### gh (GitHub CLI)

```bash
# リポジトリの作成
gh repo create

# プルリクエストの作成
gh pr create

# イシューの閲覧
gh issue list
```

### ghq (リポジトリ管理)

```bash
# リポジトリの取得
ghq get <repository-url>

# 管理下のリポジトリ一覧
ghq list
```

### tig (Git TUI)

```bash
# 基本的な起動
tig

# 特定のファイルの履歴を見る
tig <filename>

# ステータス画面を開く
tig status
```

### zoxide (cdの代替)

```bash
# ディレクトリへの移動（履歴から推測）
z <directory-name>

# インタラクティブな選択
zi
```
