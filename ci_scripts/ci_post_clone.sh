#!/bin/bash
set -euo pipefail
set -x

echo "==[post-clone] start=="

# 1) Flutter 설치/경로
git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter precache --ios

# 2) 의존성
echo "==[post-clone] flutter pub get=="
flutter pub get

# 3) iOS용 플러터 설정/Generated.xcconfig 생성
echo "==[post-clone] flutter build ios --no-codesign (generate configs)=="
flutter build ios --release --no-codesign

# 4) CocoaPods
echo "==[post-clone] pod install=="
cd ios
pod install
cd -

echo "==[post-clone] done=="
