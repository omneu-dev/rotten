#!/bin/bash
set -euo pipefail

echo "🔧 Install Flutter (stable)"
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
export PATH="$HOME/flutter/bin:$PATH"
flutter --version

echo "📦 flutter pub get"
flutter pub get

echo "🍎 cocoapods repo update (optional)"
cd ios
pod repo update
cd -
