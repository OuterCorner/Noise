#!/bin/bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
PROJ_DIR="$SCRIPTS_DIR/.."

XCBUILD="xcrun xcodebuild"

# $XCBUILD build -project "$PROJ_DIR/Noise.xcodeproj" -scheme 'Noise' -configuration Release -destination 'generic/platform=iOS'
# $XCBUILD build -project "$PROJ_DIR/Noise.xcodeproj" -scheme 'Noise' -configuration Release -destination 'generic/platform=iOS Simulator'
# $XCBUILD build -project "$PROJ_DIR/Noise.xcodeproj" -scheme 'Noise' -configuration Release -destination'generic/platform=macOS'

BUILD_DIR="$(xcodebuild -project "$PROJ_DIR/Noise.xcodeproj" -scheme 'Noise' -configuration Release -showBuildSettings | grep " BUILD_DIR " | cut -d '=' -f2 | xargs)"

rm -rf "$PROJ_DIR/Noise.xcframework"

$XCBUILD -create-xcframework \
	-framework "$BUILD_DIR/Release/Noise.framework"\
	-debug-symbols "$BUILD_DIR/Release/Noise.framework.dSYM"\
	-framework "$BUILD_DIR/Release-iphoneos/Noise.framework"\
	-debug-symbols "$BUILD_DIR/Release-iphoneos/Noise.framework.dSYM"\
	-framework "$BUILD_DIR/Release-iphonesimulator/Noise.framework"\
	-debug-symbols "$BUILD_DIR/Release-iphonesimulator/Noise.framework.dSYM" \
	-output "$PROJ_DIR/Noise.xcframework"


find "$PROJ_DIR/Noise.xcframework" -type d -name Frameworks  -exec rm -rf {} \;




