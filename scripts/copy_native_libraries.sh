#!/bin/bash

# Script to copy native libraries to macOS app bundle
# This should be run as a build phase in Xcode

set -e

echo "🔧 [Build] Copying native libraries to app bundle..."

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SRCROOT:-$(dirname "$SCRIPT_DIR")}"
RUNNER_DIR="$PROJECT_ROOT/macos/Runner"
NATIVE_DIR="$PROJECT_ROOT/native/whisper/whisper.cpp/build"
TARGET_BUILD_DIR="${TARGET_BUILD_DIR:-$PROJECT_ROOT/build/macos/Build/Products/Debug}"
APP_BUNDLE_NAME="${PRODUCT_NAME:-flutter_voice_bridge}"
APP_BUNDLE="$TARGET_BUILD_DIR/$APP_BUNDLE_NAME.app"

# Source library paths
DYLIB_SOURCE="$RUNNER_DIR/libwhisper_ffi.dylib"

# Target paths in app bundle
FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"

echo "📂 [Build] Project root: $PROJECT_ROOT"
echo "📂 [Build] Target build dir: $TARGET_BUILD_DIR"
echo "📂 [Build] App bundle: $APP_BUNDLE"
echo "📂 [Build] Source dylib: $DYLIB_SOURCE"
echo "📂 [Build] Native build dir: $NATIVE_DIR"

# Check if source dylib exists
if [ ! -f "$DYLIB_SOURCE" ]; then
    echo "❌ [Build] ERROR: libwhisper_ffi.dylib not found at $DYLIB_SOURCE"
    echo "💡 [Build] Please run the Whisper build script first:"
    echo "💡 [Build] ./scripts/build_whisper.sh"
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$FRAMEWORKS_DIR"
mkdir -p "$MACOS_DIR"

# Copy main FFI dylib
echo "📦 [Build] Copying libwhisper_ffi.dylib..."
cp "$DYLIB_SOURCE" "$FRAMEWORKS_DIR/"
cp "$DYLIB_SOURCE" "$MACOS_DIR/"
chmod 755 "$FRAMEWORKS_DIR/libwhisper_ffi.dylib"
chmod 755 "$MACOS_DIR/libwhisper_ffi.dylib"

# Fix rpath in the copied library to point to app bundle Frameworks
echo "🔧 [Build] Fixing rpath for app bundle..."
install_name_tool -delete_rpath "$NATIVE_DIR/src" "$FRAMEWORKS_DIR/libwhisper_ffi.dylib" 2>/dev/null || true
install_name_tool -delete_rpath "$NATIVE_DIR/ggml/src" "$FRAMEWORKS_DIR/libwhisper_ffi.dylib" 2>/dev/null || true
install_name_tool -delete_rpath "$NATIVE_DIR/ggml/src/ggml-blas" "$FRAMEWORKS_DIR/libwhisper_ffi.dylib" 2>/dev/null || true
install_name_tool -delete_rpath "$NATIVE_DIR/ggml/src/ggml-metal" "$FRAMEWORKS_DIR/libwhisper_ffi.dylib" 2>/dev/null || true
install_name_tool -add_rpath "@executable_path/../Frameworks" "$FRAMEWORKS_DIR/libwhisper_ffi.dylib" 2>/dev/null || true
echo "✅ [Build] rpath fixed for app bundle"

# Copy Whisper dependencies
echo "📦 [Build] Copying Whisper dependencies..."

# Main whisper library
if [ -f "$NATIVE_DIR/src/libwhisper.1.7.6.dylib" ]; then
    cp "$NATIVE_DIR/src/libwhisper.1.7.6.dylib" "$FRAMEWORKS_DIR/"
    ln -sf libwhisper.1.7.6.dylib "$FRAMEWORKS_DIR/libwhisper.1.dylib"
    echo "✅ [Build] Copied libwhisper.1.dylib"
fi

# GGML dependencies
GGML_LIBS=(
    "ggml/src/libggml.dylib"
    "ggml/src/libggml-cpu.dylib" 
    "ggml/src/libggml-base.dylib"
    "ggml/src/ggml-blas/libggml-blas.dylib"
    "ggml/src/ggml-metal/libggml-metal.dylib"
)

for lib in "${GGML_LIBS[@]}"; do
    if [ -f "$NATIVE_DIR/$lib" ]; then
        cp "$NATIVE_DIR/$lib" "$FRAMEWORKS_DIR/"
        echo "✅ [Build] Copied $(basename "$lib")"
    else
        echo "⚠️ [Build] Warning: $lib not found"
    fi
done

# Set proper permissions for all libraries
chmod 755 "$FRAMEWORKS_DIR"/*.dylib

# Verify the main dylib copy
if [ -f "$FRAMEWORKS_DIR/libwhisper_ffi.dylib" ]; then
    echo "✅ [Build] Successfully copied libwhisper_ffi.dylib to Frameworks"
    echo "📏 [Build] Size: $(ls -lh "$FRAMEWORKS_DIR/libwhisper_ffi.dylib" | awk '{print $5}')"
else
    echo "❌ [Build] Failed to copy dylib to Frameworks"
    exit 1
fi

if [ -f "$MACOS_DIR/libwhisper_ffi.dylib" ]; then
    echo "✅ [Build] Successfully copied libwhisper_ffi.dylib to MacOS"
    echo "📏 [Build] Size: $(ls -lh "$MACOS_DIR/libwhisper_ffi.dylib" | awk '{print $5}')"
else
    echo "❌ [Build] Failed to copy dylib to MacOS"
    exit 1
fi

# Count total libraries copied
TOTAL_LIBS=$(ls -1 "$FRAMEWORKS_DIR"/*.dylib 2>/dev/null | wc -l)
echo "📊 [Build] Total libraries in bundle: $TOTAL_LIBS"

echo "🎉 [Build] Native library copy completed successfully!" 