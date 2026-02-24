# Tests Directory

このディレクトリには、`install.sh` のテストスイートが含まれています。

## テストフレームワーク

**Bats (Bash Automated Testing System)** を使用しています。

インストール方法：
```bash
brew install bats-core
```

詳細: https://bats-core.readthedocs.io/

## テストファイル

| ファイル名 | 説明 |
| --- | --- |
| `test_install.bats` | install.shのメインテストスイート |

## テストカテゴリ

### 1. 構文チェック

スクリプトのシンタックスエラーを検出します。

```bash
@test "スクリプトの構文チェック" {
    run bash -n "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}
```

### 2. ログ関数のテスト

`log_info`, `log_success`, `log_warning`, `log_error` 関数が正しく動作することを確認します。

### 3. ユーティリティ関数のテスト

- `check_command`: コマンドの存在チェック
- `check_interactive`: 対話的端末の検出

### 4. オプション解析のテスト

- `--no-log`: ログ無効オプション
- `--no-color`: カラー出力無効オプション
- 複数オプションの組み合わせ

### 5. パス設定のテスト

- Apple Silicon の Homebrew パス (`/opt/homebrew`)
- Intel Mac の Homebrew パス (`/usr/local`)

### 6. chezmoi設定のバックアップテスト

既存の設定ファイルが正しくバックアップされることを確認します。

### 7. パス変数のテスト

- `cleanup_symlinks.sh` のパスが変数化されていること
- ハードコードされたパスがないこと

### 8. エラーハンドリングのテスト

- `set -euo pipefail` の設定確認
- エラー出力が正しくstderrに出力されること

### 9. ドキュメントのテスト

スクリプトに必要なドキュメントが含まれていることを確認します。

### 10. mise activateのテスト

`dot_zshrc` での mise 設定が正しいことを確認します。

## テストの実行方法

### すべてのテストを実行

プロジェクトルートから：

```bash
bash test_runner.sh
```

### 特定のテストファイルを実行

```bash
bats tests/test_install.bats
```

### 詳細な出力で実行

```bash
bats -t tests/test_install.bats
```

### 特定のテストケースのみ実行

```bash
bats -f "構文チェック" tests/test_install.bats
```

### 失敗したテストのみ再実行

```bash
bats --filter "failed" tests/test_install.bats
```

## テストの追加

新しいテストを追加するには：

1. `tests/` ディレクトリに `test_*.bats` ファイルを作成
2. 以下の形式でテストケースを記述：

```bats
@test "テストケース名" {
    # 前提条件のセットアップ
    # ...

    # テスト実行
    run コマンド

    # アサーション
    [ "$status" -eq 0 ]
    [[ "$output" =~ "期待する出力" ]]
}
```

3. テストを実行して動作を確認

## CI/CD への統合

GitHub Actionsなどでテストを実行する例：

```yaml
- name: Run tests
  run: |
    brew install bats-core
    bash test_runner.sh
```

## 注意事項

- 一部のテストは Mac 環境でのみ実行可能です（Homebrew、xcode-selectなど）
- システム全体に変更を加えるテストは含まれていません（安全のため）
- テストはスクリプトの構造とロジックを検証することに重点を置いています

## トラブルシューティング

### `command not found: bats`

Batsがインストールされていません。インストールしてください：

```bash
brew install bats-core
```

### テストがすべて失敗する

スクリプトのパスが正しいか確認してください。テストはプロジェクトルートから実行する必要があります。

### 特定のテストで失敗

```bash
# 詳細な出力で実行して原因を特定
bats -t tests/test_install.bats

# 特定のテストのみ実行
bats -f "テストケース名" tests/test_install.bats
```
