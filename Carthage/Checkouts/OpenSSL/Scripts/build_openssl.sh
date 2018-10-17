OPENSSL_TARBALL="$SRCROOT/openssl-$OPENSSL_VERSION.tar.gz"
OPENSSL_SRC="$TARGET_TEMP_DIR/openssl/"
LIB_PRODUCT_NAME="$FULL_PRODUCT_NAME"
SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [ "$PLATFORM_NAME" == "" ]; then
	echo "PLATFORM_NAME not defined"
fi

# check whether libcrypto.a already exists - we'll only build if it does not
if [ -f  "$TARGET_BUILD_DIR/$LIB_PRODUCT_NAME" ]; then
    echo "Using previously-built libary $TARGET_BUILD_DIR/$LIB_PRODUCT_NAME - skipping build"
    echo "To force a rebuild clean project and clean dependencies"
    exit 0;
else
    echo "No previously-built libary present at $TARGET_BUILD_DIR/$LIB_PRODUCT_NAME - performing build"
fi

if [ ! -f "$OPENSSL_TARBALL" ]; then
	echo "Downloading openssl-$OPENSSL_VERSION.tar.gz"
	curl -O "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" || exit 1
fi

echo "Extracting $OPENSSL_TARBALL..."
mkdir -p "$OPENSSL_SRC"
tar -C "$OPENSSL_SRC" --strip-components=1 -zxf "$OPENSSL_TARBALL" || exit 1
cd "$OPENSSL_SRC"
patch -p1 < "$SCRIPTS_DIR/iossimulator_patch.diff"

CC="xcrun -sdk $PLATFORM_NAME cc"
OPENSSL_OPTIONS="no-shared $OPENSSL_OPTIONS"

echo "Creating $LIB_PRODUCT_NAME with $OPENSSL_OPTIONS for architectures: $ARCHS"



for BUILDARCH in $ARCHS
do
	echo "Building $BUILDARCH"

	make clean

	if [ "$PLATFORM_NAME" = "macosx" ]; then
		if [ "$BUILDARCH" = "i386" ]; then
			CONFIGURE_OPTIONS="darwin-i386-cc $OPENSSL_OPTIONS"
		elif [ "$BUILDARCH" = "x86_64" ]; then
			CONFIGURE_OPTIONS="darwin64-x86_64-cc $OPENSSL_OPTIONS"
		fi
	elif [ "$PLATFORM_NAME" = "iphoneos" ]; then
		if [[ "$BUILDARCH" = "armv"* ]]; then
			CONFIGURE_OPTIONS="ios-xcrun $OPENSSL_OPTIONS"
		elif [ "$BUILDARCH" = "arm64" ]; then
			CONFIGURE_OPTIONS="ios64-xcrun $OPENSSL_OPTIONS"
		fi
	elif [ "$PLATFORM_NAME" = "iphonesimulator" ]; then
		if [ "$BUILDARCH" = "i386" ]; then
			CONFIGURE_OPTIONS="iossimulator-xcrun $OPENSSL_OPTIONS"
		elif [ "$BUILDARCH" = "x86_64" ]; then
			CONFIGURE_OPTIONS="iossimulator64-xcrun $OPENSSL_OPTIONS"
		fi
	else
		echo "Unsupported platform $PLATFORM_NAME"
		exit 1
	fi
	
	./Configure  $CONFIGURE_OPTIONS -fembed-bitcode -openssldir="$BUILD_DIR"
	
    make depend
    make

	echo "Creating $LIB_PRODUCT_NAME for $BUILDARCH in $TARGET_TEMP_DIR"
    libtool -static libcrypto.a libssl.a -o "$TARGET_TEMP_DIR/$BUILDARCH-$LIB_PRODUCT_NAME"
done


echo "Creating universal archive in $TARGET_BUILD_DIR"
mkdir -p "$TARGET_BUILD_DIR"
lipo -create "$TARGET_TEMP_DIR/"*-$LIB_PRODUCT_NAME -output "$TARGET_BUILD_DIR/$LIB_PRODUCT_NAME"

echo "Executing ranlib"
ranlib "$TARGET_BUILD_DIR/$LIB_PRODUCT_NAME"

echo "Copying Headers"
mkdir -p "$TARGET_BUILD_DIR/headers"
cp -RLf "$OPENSSL_SRC/include/" "$TARGET_BUILD_DIR/headers"
