
set -euo pipefail

set -x
echo "== Xcode Cloud post-clone start =="

if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
flutter --version
flutter pub get

flutter precache --ios

flutter build ios --release --no-codesign

cd ios

rm -rf Pods Podfile.lock

pod repo update

pod install

cd ..

echo "== Check important files =="

ls -la ios/Flutter || true

ls -la ios/Flutter/Generated.xcconfig || true

ls -la ios/Pods/Target\ Support\ Files/Pods-Runner || true

echo "== Xcode Cloud post-clone done =="

