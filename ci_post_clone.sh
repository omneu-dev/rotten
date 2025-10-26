#!/bin/bash
set -euo pipefail

echo "🔧 Install Flutter (stable)"
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
export PATH="$HOME/flutter/bin:$PATH"
flutter --version

echo "📦 pub get"
flutter pub get

echo "📦 iOS pods"
cd ios
pod install --repo-update
cd ..

echo "🧱 Pre-generate iOS artifacts"
flutter precache --ios
flutter build ios --release --no-codesign

echo "✅ post-clone done"
