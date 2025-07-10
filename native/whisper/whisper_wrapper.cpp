#include "whisper_wrapper.h"
#include "whisper.h"
#include <cstring>
#include <vector>
#include <iostream>
#include <cstdlib>

extern "C" {

whisper_context* whisper_ffi_init(const char* model_path) {
    try {
        // Use the modern API with default parameters
        struct whisper_context_params cparams = whisper_context_default_params();
        struct whisper_context* ctx = whisper_init_from_file_with_params(model_path, cparams);
        return ctx;
    } catch (...) {
        return nullptr;
    }
}

char* whisper_ffi_transcribe(whisper_context* ctx, const char* audio_path) {
    if (!ctx || !audio_path) return nullptr;
    
    try {
        // This is a simplified implementation
        // In a real implementation, you would:
        // 1. Load the audio file using a library like libsndfile or ffmpeg
        // 2. Convert to required format (16kHz, mono, float32)
        // 3. Run whisper_full() with the audio data
        // 4. Extract and return the transcribed text
        
        // For now, return a placeholder to test the FFI integration
        const char* result = "Whisper FFI integration working! Real audio transcription requires audio loading implementation.";
        size_t len = strlen(result);
        char* copy = (char*)malloc(len + 1);
        if (copy) {
            strcpy(copy, result);
        }
        return copy;
        
    } catch (...) {
        return nullptr;
    }
}

void whisper_ffi_free(whisper_context* ctx) {
    if (ctx) {
        whisper_free(ctx);
    }
}

void whisper_ffi_free_string(char* str) {
    if (str) {
        free(str);
    }
}

}
