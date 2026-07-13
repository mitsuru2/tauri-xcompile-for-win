#!/bin/bash
set -uo pipefail

# clang-cl(cargo-xwin)によるコンパイラファミリー自動判定が、この環境では
# プリプロセッサのテスト実行に失敗し無害な警告を出す。
# cc-rs側は実行ファイル名から正しくMSVC(clang-cl)にフォールバックするため
# ビルド結果には影響しないが、将来の実害がある警告を見逃さないよう
# この既知パターンのみをログから除外する。
IGNORE_PATTERN='Compiler family detection failed due to error: ToolExecError'

tauri build "$@" 2>&1 | grep -v "$IGNORE_PATTERN"
exit "${PIPESTATUS[0]}"
