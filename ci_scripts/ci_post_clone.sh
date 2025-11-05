#!/bin/bash
set -euo pipefail

echo "🔧 Install Flutter (stable)"
git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
# iOS 관련 아티팩트 미리 받기
flutter precache --ios

echo "📦 flutter pub get"
# 저장소 루트(=pubspec.yaml 있는 곳)에서 실행
flutter pub get

echo "🛠️ Generate iOS Flutter configs (creates ios/Flutter/Generated.xcconfig)"
# 서명 없이 구성파일/에페메럴 파일 생성
flutter build ios --release --no-codesign

echo "📚 CocoaPods install"
cd ios
pod install --repo-update
cd -
