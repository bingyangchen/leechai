#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$(realpath "$0")")/../common.sh"

check_triggered_by_make

cd mobile
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios
pod repo update
pod install
cd ..
flutter build ipa --release
