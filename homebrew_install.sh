#!/bin/bash

### 不可視ファイルを可視化する(再起動したら見える)
defaults write com.apple.finder AppleShowAllFiles TRUE

### Command Line Tools
echo "Command Line Tools for Xcodeのインストール"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
else
  echo "Command Line Tools explicitly installed."
fi

### homebrew
echo "installing homebrew...homebrewをインストールしています"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew already installed."
fi

echo "run brew doctor..."
if command -v brew >/dev/null 2>&1; then
  brew doctor
fi

echo "run brew update..."
if command -v brew >/dev/null 2>&1; then
  brew update
fi

echo "ok. run brew upgrade..."
brew upgrade

### .Brewfileに記載されているアプリをインストール
# --global オプションはホームディレクトリの .Brewfile を参照します。
# リンクが貼られていることを前提としています。
brew bundle --global --verbose
