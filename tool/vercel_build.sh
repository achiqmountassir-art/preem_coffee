#!/usr/bin/env bash
# Build Flutter Web release output for Vercel.
set -euo pipefail

FLUTTER_SDK="${FLUTTER_ROOT:-$HOME/flutter}"
export PATH="$FLUTTER_SDK/bin:$PATH"

flutter build web --release --base-href /
