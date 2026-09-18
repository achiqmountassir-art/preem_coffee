#!/usr/bin/env bash
# Install Flutter SDK + project deps for Vercel Linux builds.
set -euo pipefail

FLUTTER_SDK="${FLUTTER_ROOT:-$HOME/flutter}"

if [ ! -x "$FLUTTER_SDK/bin/flutter" ]; then
  echo "Cloning Flutter stable SDK..."
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    --branch stable \
    "$FLUTTER_SDK"
fi

export PATH="$FLUTTER_SDK/bin:$PATH"

flutter config --no-analytics --enable-web
flutter precache --web
flutter pub get
