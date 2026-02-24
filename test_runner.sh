#!/bin/bash
# test_runner.sh
# Batsテストを実行するためのスクリプト

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "  Dotfiles Setup Tests"
echo "=========================================="
echo ""

# Check if bats is installed
if ! command -v bats >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} Bats (Bash Automated Testing System) がインストールされていません。"
    echo ""
    echo "インストールするには以下を実行してください："
    echo "  brew install bats-core"
    echo ""
    echo "または、以下を直接実行："
    echo "  brew install bats"
    echo ""
    exit 1
fi

# Check bats-core version
BATS_VERSION=$(bats --version || echo "unknown")
echo -e "${BLUE}[INFO]${NC} Bats version: $BATS_VERSION"
echo ""

# Run tests
echo "テストを実行しています..."
echo ""

TEST_DIR="$(cd "$(dirname "$0")" && pwd)/tests"

if [ ! -d "$TEST_DIR" ]; then
    echo -e "${RED}[ERROR]${NC} テストディレクトリが見つかりません: $TEST_DIR"
    exit 1
fi

# Run all test files
if bats "$TEST_DIR"/test_*.bats; then
    echo ""
    echo -e "${GREEN}[SUCCESS]${NC} すべてのテストがパスしました！"
    exit 0
else
    echo ""
    echo -e "${RED}[ERROR]${NC} 一部のテストが失敗しました。"
    exit 1
fi
