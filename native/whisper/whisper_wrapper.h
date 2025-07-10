#ifndef WHISPER_WRAPPER_H
#define WHISPER_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Simplified C API for Dart FFI
typedef struct whisper_context whisper_context;

// Initialize Whisper with model file
whisper_context* whisper_ffi_init(const char* model_path);

// Transcribe audio file
char* whisper_ffi_transcribe(whisper_context* ctx, const char* audio_path);

// Free Whisper context
void whisper_ffi_free(whisper_context* ctx);

// Free string returned by whisper_transcribe
void whisper_ffi_free_string(char* str);

#ifdef __cplusplus
}
#endif

#endif // WHISPER_WRAPPER_H
