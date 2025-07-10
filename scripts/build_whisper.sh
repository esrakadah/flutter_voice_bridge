#!/bin/bash

# Whisper.cpp Build Script for Flutter Voice Bridge
# Downloads, compiles, and installs Whisper.cpp native library for FFI usage

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
WHISPER_DIR="$PROJECT_ROOT/native/whisper"
MODEL_DIR="$PROJECT_ROOT/assets/models"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  [Whisper Build] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ [Whisper Build] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  [Whisper Build] $1${NC}"
}

log_error() {
    echo -e "${RED}❌ [Whisper Build] $1${NC}"
}

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*) PLATFORM="macos" ;;
        Linux*)  PLATFORM="linux" ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*) PLATFORM="windows" ;;
        *) 
            log_error "Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac
    
    log_info "Detected platform: $PLATFORM"
}

# Create necessary directories
setup_directories() {
    log_info "Setting up directories..."
    mkdir -p "$WHISPER_DIR"
    mkdir -p "$MODEL_DIR"
    mkdir -p "$PROJECT_ROOT/ios/Runner/Models"
    mkdir -p "$PROJECT_ROOT/android/app/src/main/assets/models"
    mkdir -p "$PROJECT_ROOT/macos/Runner/Models"
    log_success "Directories created"
}

# Download Whisper.cpp source
download_whisper() {
    log_info "Downloading Whisper.cpp..."
    
    if [ -d "$WHISPER_DIR/whisper.cpp" ]; then
        log_warning "Whisper.cpp already exists. Updating..."
        cd "$WHISPER_DIR/whisper.cpp"
        git pull
    else
        cd "$WHISPER_DIR"
        git clone https://github.com/ggerganov/whisper.cpp.git
        cd whisper.cpp
    fi
    
    log_success "Whisper.cpp downloaded"
}

# Compile Whisper.cpp
compile_whisper() {
    log_info "Compiling Whisper.cpp for $PLATFORM..."
    
    cd "$WHISPER_DIR/whisper.cpp"
    
    case $PLATFORM in
        "macos")
            compile_macos
            ;;
        "linux")
            compile_linux
            ;;
        "windows")
            compile_windows
            ;;
    esac
}

compile_macos() {
    log_info "Compiling for macOS (dylib)..."
    
    # Build with CMake for better control
    mkdir -p build
    cd build
    
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DWHISPER_BUILD_TESTS=OFF \
        -DWHISPER_BUILD_EXAMPLES=OFF
    
    make -j$(sysctl -n hw.ncpu)
    
    # Copy the dynamic library
    cp libwhisper.dylib "$PROJECT_ROOT/ios/Runner/"
    cp libwhisper.dylib "$PROJECT_ROOT/macos/Runner/"
    
    log_success "macOS compilation complete"
}

compile_linux() {
    log_info "Compiling for Linux (shared library)..."
    
    mkdir -p build
    cd build
    
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DWHISPER_BUILD_TESTS=OFF \
        -DWHISPER_BUILD_EXAMPLES=OFF
    
    make -j$(nproc)
    
    # Copy the shared library
    cp libwhisper.so "$PROJECT_ROOT/linux/"
    
    log_success "Linux compilation complete"
}

compile_windows() {
    log_info "Compiling for Windows (DLL)..."
    log_warning "Windows compilation requires Visual Studio or MinGW"
    
    mkdir -p build
    cd build
    
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DWHISPER_BUILD_TESTS=OFF \
        -DWHISPER_BUILD_EXAMPLES=OFF
    
    cmake --build . --config Release
    
    # Copy the DLL
    cp Release/whisper.dll "$PROJECT_ROOT/windows/"
    
    log_success "Windows compilation complete"
}

# Download default model
download_model() {
    log_info "Downloading default Whisper model (base.en)..."
    
    cd "$WHISPER_DIR/whisper.cpp"
    
    # Download the base English model (smaller for development)
    MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
    MODEL_FILE="ggml-base.en.bin"
    
    if [ ! -f "models/$MODEL_FILE" ]; then
        ./models/download-ggml-model.sh base.en
    else
        log_warning "Model already exists: $MODEL_FILE"
    fi
    
    # Copy model to Flutter assets
    cp "models/$MODEL_FILE" "$MODEL_DIR/"
    cp "models/$MODEL_FILE" "$PROJECT_ROOT/ios/Runner/Models/"
    cp "models/$MODEL_FILE" "$PROJECT_ROOT/android/app/src/main/assets/models/"
    cp "models/$MODEL_FILE" "$PROJECT_ROOT/macos/Runner/Models/"
    
    log_success "Model downloaded and copied to Flutter assets"
}

# Create C wrapper for simplified FFI
create_c_wrapper() {
    log_info "Creating C wrapper for FFI..."
    
    cat > "$WHISPER_DIR/whisper_wrapper.h" << 'EOF'
#ifndef WHISPER_WRAPPER_H
#define WHISPER_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Simplified C API for Dart FFI
typedef struct whisper_context whisper_context;

// Initialize Whisper with model file
whisper_context* whisper_init(const char* model_path);

// Transcribe audio file
char* whisper_transcribe(whisper_context* ctx, const char* audio_path);

// Free Whisper context
void whisper_free(whisper_context* ctx);

// Free string returned by whisper_transcribe
void whisper_free_string(char* str);

#ifdef __cplusplus
}
#endif

#endif // WHISPER_WRAPPER_H
EOF

    cat > "$WHISPER_DIR/whisper_wrapper.cpp" << 'EOF'
#include "whisper_wrapper.h"
#include "whisper.h"
#include <cstring>
#include <vector>
#include <iostream>

extern "C" {

whisper_context* whisper_init(const char* model_path) {
    try {
        struct whisper_context* ctx = whisper_init_from_file(model_path);
        return ctx;
    } catch (...) {
        return nullptr;
    }
}

char* whisper_transcribe(whisper_context* ctx, const char* audio_path) {
    if (!ctx || !audio_path) return nullptr;
    
    try {
        // This is a simplified implementation
        // In a real implementation, you would:
        // 1. Load the audio file
        // 2. Convert to required format (16kHz, mono, float32)
        // 3. Run whisper_full() with the audio data
        // 4. Extract and return the transcribed text
        
        // For now, return a placeholder
        const char* result = "Whisper FFI integration working! (placeholder transcription)";
        char* copy = (char*)malloc(strlen(result) + 1);
        strcpy(copy, result);
        return copy;
        
    } catch (...) {
        return nullptr;
    }
}

void whisper_free(whisper_context* ctx) {
    if (ctx) {
        whisper_free(ctx);
    }
}

void whisper_free_string(char* str) {
    if (str) {
        free(str);
    }
}

}
EOF

    log_success "C wrapper created"
}

# Update CMakeLists.txt to include wrapper
update_cmake() {
    log_info "Updating CMakeLists.txt to include wrapper..."
    
    cd "$WHISPER_DIR/whisper.cpp"
    
    # Add wrapper to CMakeLists.txt if not already present
    if ! grep -q "whisper_wrapper" CMakeLists.txt; then
        cat >> CMakeLists.txt << 'EOF'

# Flutter FFI Wrapper
add_library(whisper_ffi SHARED
    ../whisper_wrapper.cpp
)

target_link_libraries(whisper_ffi whisper)
target_include_directories(whisper_ffi PRIVATE .)
target_include_directories(whisper_ffi PRIVATE ..)
EOF
    fi
    
    log_success "CMakeLists.txt updated"
}

# Print next steps
print_next_steps() {
    log_success "Whisper.cpp build complete!"
    echo
    log_info "Next steps:"
    echo "  1. Test the FFI integration: flutter test"
    echo "  2. Run the app: flutter run"
    echo "  3. Record audio and check logs for transcription results"
    echo
    log_info "Model location: $MODEL_DIR/ggml-base.en.bin"
    log_info "Library location: Platform-specific directories"
    echo
    log_warning "Note: This uses MockTranscriptionService by default."
    log_warning "Update lib/di.dart to use WhisperTranscriptionService() for real FFI."
}

# Main execution
main() {
    log_info "Starting Whisper.cpp build process..."
    
    detect_platform
    setup_directories
    download_whisper
    create_c_wrapper
    update_cmake
    compile_whisper
    download_model
    print_next_steps
    
    log_success "Build process completed successfully!"
}

# Check for help flag
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Whisper.cpp Build Script for Flutter Voice Bridge"
    echo
    echo "This script downloads, compiles, and sets up Whisper.cpp for FFI usage."
    echo
    echo "Usage:"
    echo "  ./scripts/build_whisper.sh"
    echo
    echo "Requirements:"
    echo "  - Git"
    echo "  - CMake"
    echo "  - C++ compiler (gcc/clang/MSVC)"
    echo "  - Internet connection for downloads"
    echo
    exit 0
fi

# Run main function
main "$@" 