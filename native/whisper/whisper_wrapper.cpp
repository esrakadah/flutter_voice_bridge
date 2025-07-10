#include "whisper_wrapper.h"
#include "whisper.h"
#include <cstring>
#include <vector>
#include <iostream>
#include <fstream> // Required for file operations
#include <cstdlib>

// Helper function to read WAV file
// This is a simplified implementation and assumes a specific WAV format
bool read_wav(const std::string &fname, std::vector<float> &pcmf32, std::vector<std::vector<float>> &pcmf32s) {
    std::ifstream file(fname, std::ios::binary);
    if (!file) {
        return false;
    }

    // Read WAV header
    char header[44];
    file.read(header, 44);

    // Simple check for WAV format
    if (strncmp(header, "RIFF", 4) != 0 || strncmp(header + 8, "WAVE", 4) != 0) {
        return false;
    }
    
    // Assuming 16-bit PCM mono
    int16_t sample;
    while(file.read(reinterpret_cast<char*>(&sample), sizeof(int16_t))) {
        pcmf32.push_back(static_cast<float>(sample) / 32768.0f);
    }

    return true;
}

extern "C" {

whisper_context* whisper_ffi_init(const char* model_path) {
    try {
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
        std::vector<float> pcmf32;
        std::vector<std::vector<float>> pcmf32s;

        if (!read_wav(audio_path, pcmf32, pcmf32s)) {
            std::cerr << "Failed to read WAV file: " << audio_path << std::endl;
            return nullptr;
        }

        whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
        wparams.print_progress = false;

        if (whisper_full(ctx, wparams, pcmf32.data(), pcmf32.size()) != 0) {
            std::cerr << "Failed to process audio" << std::endl;
            return nullptr;
        }

        const int n_segments = whisper_full_n_segments(ctx);
        std::string result_text = "";

        for (int i = 0; i < n_segments; ++i) {
            const char* text = whisper_full_get_segment_text(ctx, i);
            result_text += text;
        }

        char* result = new char[result_text.length() + 1];
        strcpy(result, result_text.c_str());
        return result;
        
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
        delete[] str; // Use delete[] for memory allocated with new[]
    }
}

}
