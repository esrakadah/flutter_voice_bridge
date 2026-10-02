#!/bin/bash
# Builds the Whisper FFI library for macOS and downloads the base.en model.
# Re-runnable: a second run reuses the pinned checkout and the downloaded model.

set -euo pipefail

WHISPER_CPP_TAG="v1.7.6"
WHISPER_CPP_REPO="https://github.com/ggml-org/whisper.cpp.git"
MODEL_NAME="base.en"
MACOS_DEPLOYMENT_TARGET="13.3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NATIVE_DIR="$PROJECT_ROOT/native/whisper"
WHISPER_CPP_DIR="$NATIVE_DIR/whisper.cpp"
BUILD_DIR="$NATIVE_DIR/build"
MODEL_DIR="$PROJECT_ROOT/assets/models"
MODEL_FILE="ggml-$MODEL_NAME.bin"
# Exact size of ggml-base.en.bin; a smaller file is an interrupted download or an HTTP error page.
MODEL_BYTES=147964211

log_info() { echo "ℹ️  [Whisper Build] $1"; }
log_success() { echo "✅ [Whisper Build] $1"; }
log_error() { echo "❌ [Whisper Build] $1" >&2; }

usage() {
    cat <<USAGE
Builds libwhisper_ffi.dylib (whisper.cpp $WHISPER_CPP_TAG) and downloads the $MODEL_NAME model.

Usage: ./scripts/build_whisper.sh

Requirements: macOS, git, cmake, Xcode command line tools, internet for the first run.
Output: $BUILD_DIR/lib (copied into the app by the macOS "Copy Native Libraries" build phase)
        $MODEL_DIR/$MODEL_FILE
USAGE
}

require_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        log_error "Only macOS is supported. iOS and Android use a mock transcription service."
        exit 1
    fi
    for tool in git cmake; do
        command -v "$tool" >/dev/null || { log_error "Missing $tool (brew install $tool)"; exit 1; }
    done
}

checkout_whisper_cpp() {
    if [[ -d "$WHISPER_CPP_DIR/.git" ]]; then
        local current_tag
        current_tag="$(git -C "$WHISPER_CPP_DIR" describe --tags --exact-match 2>/dev/null || true)"
        if [[ "$current_tag" == "$WHISPER_CPP_TAG" ]]; then
            log_info "whisper.cpp $WHISPER_CPP_TAG already checked out"
            return
        fi
        log_info "Switching whisper.cpp from ${current_tag:-an untagged commit} to $WHISPER_CPP_TAG"
        git -C "$WHISPER_CPP_DIR" fetch --depth 1 origin tag "$WHISPER_CPP_TAG"
        git -C "$WHISPER_CPP_DIR" checkout --force --quiet "$WHISPER_CPP_TAG"
    else
        log_info "Cloning whisper.cpp $WHISPER_CPP_TAG"
        git clone --quiet --depth 1 --branch "$WHISPER_CPP_TAG" "$WHISPER_CPP_REPO" "$WHISPER_CPP_DIR"
    fi
}

build_library() {
    log_info "Compiling libwhisper_ffi.dylib (macOS $MACOS_DEPLOYMENT_TARGET+, $(uname -m))"
    cmake -S "$NATIVE_DIR" -B "$BUILD_DIR" -Wno-dev \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_CCACHE=OFF \
        -DGGML_OPENMP=OFF \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOS_DEPLOYMENT_TARGET" \
        -DCMAKE_INSTALL_RPATH="@loader_path" \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        >/dev/null
    cmake --build "$BUILD_DIR" --config Release --parallel "$(sysctl -n hw.ncpu)" >/dev/null
    log_success "Built $BUILD_DIR/lib/libwhisper_ffi.dylib"
}

model_is_complete() {
    [[ -f "$1" ]] && [[ "$(stat -f%z "$1")" == "$MODEL_BYTES" ]]
}

download_model() {
    mkdir -p "$MODEL_DIR"
    local model_path="$MODEL_DIR/$MODEL_FILE"
    if model_is_complete "$model_path"; then
        log_info "Model already present: $model_path"
        return
    fi
    if [[ -e "$model_path" ]]; then
        log_info "Replacing an incomplete model file ($(stat -f%z "$model_path") of $MODEL_BYTES bytes)"
        rm -f "$model_path"
    fi

    log_info "Downloading $MODEL_FILE (~147 MB)"
    local download_dir
    download_dir="$(mktemp -d)"
    bash "$WHISPER_CPP_DIR/models/download-ggml-model.sh" "$MODEL_NAME" "$download_dir"
    if ! model_is_complete "$download_dir/$MODEL_FILE"; then
        rm -rf "$download_dir"
        log_error "Downloaded model has the wrong size (expected $MODEL_BYTES bytes). Run the script again."
        exit 1
    fi
    mv "$download_dir/$MODEL_FILE" "$model_path"
    rm -rf "$download_dir"
    log_success "Model saved to $model_path"
}

main() {
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        usage
        exit 0
    fi
    require_macos
    checkout_whisper_cpp
    build_library
    download_model
    log_success "Done. Run: flutter run -d macos"
}

main "$@"
