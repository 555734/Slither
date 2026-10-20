#!/usr/bin/env bash
# Android 用のデバッグ APK を書き出す。
#
# 事前準備（一度だけ）：
#   1. Godot 4.4.1 本体と、同じ版のエクスポートテンプレート
#      （~/.local/share/godot/export_templates/4.4.1.stable/ に android_debug.apk などを置く）
#   2. JDK 17 以降
#   3. Android SDK：platform-tools、build-tools;35.0.0、platforms;android-35
#   4. Godot のエディタ設定（editor_settings-4.4.tres）に
#      export/android/android_sdk_path、java_sdk_path、debug_keystore を設定
#      （エディタを一度起動すると、デバッグ用キーストアは自動で作られる）
#
# 使い方：GODOT=/path/to/godot game/tools/build_android.sh
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mkdir -p ../build
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-debug "Android" ../build/oshiri-mvp-debug.apk
echo "書き出し先: $(cd ../build && pwd)/oshiri-mvp-debug.apk"
