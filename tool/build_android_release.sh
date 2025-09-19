#!/usr/bin/env bash
set -euo pipefail

# Helper script to bump the pubspec version code before building the APK.
# Usage: ./tool/build_android_release.sh [bump-options] [--] [flutter build flags]
# Any arguments before `--` are forwarded to bump_version.dart. Arguments after
# `--` are passed directly to `flutter build`.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

BUMP_ARGS=()
BUILD_ARGS=()
FORWARD_TO_BUILD=0
SKIP_BUMP=0

if ! command -v dart >/dev/null 2>&1; then
  echo '❌ dart command not found. Install Flutter/Dart SDK first.' >&2
  exit 127
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo '❌ flutter command not found. Install the Flutter SDK before running this script.' >&2
  exit 127
fi

for arg in "$@"; do
  if [[ $FORWARD_TO_BUILD -eq 1 ]]; then
    BUILD_ARGS+=("$arg")
    continue
  fi
  case $arg in
    --no-bump)
      SKIP_BUMP=1
      ;;
    --bump=*|--set-name=*|--set-build=*|--dry-run)
      BUMP_ARGS+=("$arg")
      ;;
    --)
      FORWARD_TO_BUILD=1
      ;;
    *)
      BUILD_ARGS+=("$arg")
      ;;
  esac
done

if [[ $SKIP_BUMP -eq 1 ]]; then
  echo 'ℹ️  Skipping version bump (--no-bump)'
elif [[ ${#BUMP_ARGS[@]} -gt 0 ]]; then
  echo '⏫ Bumping version with custom arguments:' "${BUMP_ARGS[@]}"
  dart run tool/bump_version.dart "${BUMP_ARGS[@]}"
else
  echo '⏫ Bumping build number in pubspec.yaml'
  dart run tool/bump_version.dart
fi

echo '🚀 Building Android release APK'
flutter build apk --release "${BUILD_ARGS[@]}"
