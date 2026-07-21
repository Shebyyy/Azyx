#!/usr/bin/env bash
set -e

###############################################
# Cross-Platform Flutter Rename Script (ALPHA)
# Handles package name & app display name changes
# Ported from AnymeX-Preview's scripts/rename_app.sh
# and adapted to Azyx's actual project layout.
###############################################

###############################################
# Color Output
###############################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}➡${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; exit 1; }
log_success() { echo -e "${GREEN}✔${NC} $1"; }

###############################################
# Detect OS & Configure sed
###############################################
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=(-i '')
else
  SED_INPLACE=(-i)
fi

###############################################
# Configuration Variables (Azyx)
###############################################
OLD_PKG="com.example.azyx"
NEW_PKG="com.example.azyxalpha"

OLD_DIR="com/example/azyx"
NEW_DIR="com/example/azyxalpha"

OLD_APP_NAME="azyx"
NEW_APP_NAME="Azyx α"
NEW_BINARY_NAME="azyx_alpha"

ANDROID_SRC="android/app/src/main/kotlin"
MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"

IOS_PROJECT="ios/Runner.xcodeproj/project.pbxproj"
IOS_PLIST="ios/Runner/Info.plist"

MACOS_CONFIG="macos/Runner/Configs/AppInfo.xcconfig"
MACOS_INFO="macos/Runner/Info.plist"

LINUX_MAIN="linux/my_application.cc"
LINUX_CMAKE="linux/CMakeLists.txt"

WINDOWS_RC="windows/runner/Runner.rc"
WINDOWS_CMAKE="windows/CMakeLists.txt"
WINDOWS_MAIN="windows/runner/main.cpp"

###############################################
# Validate Arguments
###############################################
if [ -z "$1" ]; then
  log_error "Usage: $0 <pubspec_version> [display_version]"
fi

NEW_VERSION="$1"      # For pubspec.yaml (e.g., 2.6.4-alpha+4)
DISPLAY_VERSION="$2"  # Optional, kept for parity with the tag naming used in CI

if [ -z "$DISPLAY_VERSION" ]; then
  SEMVER=$(echo "$NEW_VERSION" | cut -d'+' -f1)
  DISPLAY_VERSION="v${SEMVER}"
fi

echo "════════════════════════════════════════════"
echo "  Azyx Cross-Platform Alpha Rename"
echo "════════════════════════════════════════════"
echo "  Old Package: $OLD_PKG"
echo "  New Package: $NEW_PKG"
echo "  Old Name:    $OLD_APP_NAME"
echo "  New Name:    $NEW_APP_NAME"
echo "  Pubspec Version: $NEW_VERSION"
echo "  Display Version: $DISPLAY_VERSION"
echo "════════════════════════════════════════════"
echo ""

###############################################
# Check if already alpha
###############################################
if [ -d "$ANDROID_SRC/$NEW_DIR" ]; then
  log_warn "Already converted to alpha. Skipping package rename."
  SKIP_PACKAGE_RENAME=true
else
  SKIP_PACKAGE_RENAME=false
fi

###############################################
# ANDROID
###############################################
log_info "ANDROID: Updating configuration..."

if [ -f "android/app/build.gradle.kts" ]; then
  BUILD_GRADLE="android/app/build.gradle.kts"
elif [ -f "android/app/build.gradle" ]; then
  BUILD_GRADLE="android/app/build.gradle"
else
  log_warn "build.gradle not found!"
fi

if [ -n "$BUILD_GRADLE" ] && [ "$SKIP_PACKAGE_RENAME" = false ]; then
  sed "${SED_INPLACE[@]}" -E "s|applicationId[[:space:]]*=[[:space:]]*\"[^\"]*\"|applicationId = \"$NEW_PKG\"|g" "$BUILD_GRADLE"
  sed "${SED_INPLACE[@]}" -E "s|namespace[[:space:]]*=[[:space:]]*\"[^\"]*\"|namespace = \"$NEW_PKG\"|g" "$BUILD_GRADLE"
  log_success "Updated $BUILD_GRADLE"
fi

if [ -f "$MANIFEST_FILE" ]; then
  if [ "$SKIP_PACKAGE_RENAME" = false ]; then
    sed "${SED_INPLACE[@]}" "s|package=\"$OLD_PKG\"|package=\"$NEW_PKG\"|g" "$MANIFEST_FILE"
  fi
  sed "${SED_INPLACE[@]}" "s|android:label=\"$OLD_APP_NAME\"|android:label=\"$NEW_APP_NAME\"|g" "$MANIFEST_FILE"
  log_success "Updated AndroidManifest.xml"
fi

if [ "$SKIP_PACKAGE_RENAME" = false ] && [ -d "$ANDROID_SRC/$OLD_DIR" ]; then
  mkdir -p "$ANDROID_SRC/$NEW_DIR"
  find "$ANDROID_SRC/$OLD_DIR" -type f -name "*.kt" -exec sed "${SED_INPLACE[@]}" "s|package $OLD_PKG|package $NEW_PKG|g" {} \;
  cp -r "$ANDROID_SRC/$OLD_DIR"/* "$ANDROID_SRC/$NEW_DIR"/ 2>/dev/null || true
  rm -rf "${ANDROID_SRC:?}/$OLD_DIR"
  log_success "Moved Kotlin files to new package"
fi

###############################################
# iOS
###############################################
log_info "iOS: Updating configuration..."

if [ -f "$IOS_PROJECT" ] && [ "$SKIP_PACKAGE_RENAME" = false ]; then
  sed "${SED_INPLACE[@]}" "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" "$IOS_PROJECT"
  sed "${SED_INPLACE[@]}" "s|PRODUCT_BUNDLE_IDENTIFIER = ${OLD_PKG}\.RunnerTests|PRODUCT_BUNDLE_IDENTIFIER = ${NEW_PKG}.RunnerTests|g" "$IOS_PROJECT"
  log_success "Updated iOS bundle identifiers"
fi

if [ -f "$IOS_PLIST" ]; then
  sed "${SED_INPLACE[@]}" -E '/<key>CFBundleDisplayName<\/key>/{n;s|<string>[^<]*</string>|<string>'"$NEW_APP_NAME"'</string>|;}' "$IOS_PLIST"
  log_success "Updated iOS Info.plist display name"
fi

###############################################
# macOS
###############################################
log_info "macOS: Updating configuration..."

if [ -f "$MACOS_CONFIG" ]; then
  if [ "$SKIP_PACKAGE_RENAME" = false ]; then
    sed "${SED_INPLACE[@]}" "s|PRODUCT_NAME = azyx|PRODUCT_NAME = $NEW_BINARY_NAME|g" "$MACOS_CONFIG"
    sed "${SED_INPLACE[@]}" "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" "$MACOS_CONFIG"
  fi
  log_success "Updated macOS xcconfig"
fi

###############################################
# Linux
###############################################
log_info "Linux: Updating configuration..."

if [ -f "$LINUX_MAIN" ]; then
  sed "${SED_INPLACE[@]}" "s|\"$OLD_APP_NAME\"|\"$NEW_APP_NAME\"|g" "$LINUX_MAIN"
  log_success "Updated Linux application title"
fi

if [ -f "$LINUX_CMAKE" ]; then
  sed "${SED_INPLACE[@]}" 's|set(BINARY_NAME "azyx")|set(BINARY_NAME "'"$NEW_BINARY_NAME"'")|g' "$LINUX_CMAKE"
  log_success "Updated Linux CMakeLists.txt"
fi

###############################################
# Windows
###############################################
log_info "Windows: Updating configuration..."

if [ -f "$WINDOWS_RC" ]; then
  sed "${SED_INPLACE[@]}" "s|\"azyx\"|\"$NEW_BINARY_NAME\"|g" "$WINDOWS_RC"
  sed "${SED_INPLACE[@]}" "s|\"azyx\.exe\"|\"$NEW_BINARY_NAME.exe\"|g" "$WINDOWS_RC"
  sed "${SED_INPLACE[@]}" 's|VALUE "ProductName", "[^"]*"|VALUE "ProductName", "'"$NEW_APP_NAME"'"|g' "$WINDOWS_RC"
  sed "${SED_INPLACE[@]}" 's|VALUE "FileDescription", "[^"]*"|VALUE "FileDescription", "'"$NEW_APP_NAME"'"|g' "$WINDOWS_RC"
  log_success "Updated Windows Runner.rc"
fi

if [ -f "$WINDOWS_CMAKE" ]; then
  sed "${SED_INPLACE[@]}" "s|set(BINARY_NAME \"azyx\")|set(BINARY_NAME \"$NEW_BINARY_NAME\")|g" "$WINDOWS_CMAKE"
  sed "${SED_INPLACE[@]}" 's|project(azyx LANGUAGES CXX)|project('"$NEW_BINARY_NAME"' LANGUAGES CXX)|g' "$WINDOWS_CMAKE"
  log_success "Updated Windows CMakeLists.txt"
fi

if [ -f "$WINDOWS_MAIN" ]; then
  sed "${SED_INPLACE[@]}" "s|window.Create(L\\\"azyx\\\"|window.Create(L\\\"$NEW_APP_NAME\\\"|g" "$WINDOWS_MAIN"
  log_success "Updated Windows main.cpp window title"
fi

###############################################
# Flutter pubspec.yaml
###############################################
log_info "Flutter: Updating pubspec.yaml..."

if [ -f "pubspec.yaml" ]; then
  sed "${SED_INPLACE[@]}" "s|^version: .*|version: $NEW_VERSION|g" pubspec.yaml
  log_success "Updated version to $NEW_VERSION"
fi

###############################################
# DART: Update user-visible "AzyX" storage-folder strings
# (Azyx pulls its current version from PackageInfo at runtime,
#  so unlike AnymeX there is no hardcoded version string to patch.)
###############################################
log_info "Dart: Updating user-visible app name strings..."

for f in lib/Database/database.dart lib/storage_provider.dart lib/Screens/Manga/Read/view/read.dart; do
  if [ -f "$f" ]; then
    sed "${SED_INPLACE[@]}" "s|'AzyX'|'${NEW_APP_NAME}'|g; s|\"AzyX\"|\"${NEW_APP_NAME}\"|g" "$f"
    log_success "Updated $f"
  else
    log_warn "$f not found. Skipping."
  fi
done

log_success "Azyx alpha rename complete!"
