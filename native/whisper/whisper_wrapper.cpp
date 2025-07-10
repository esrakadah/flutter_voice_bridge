#include "whisper_wrapper.h"
#include "whisper.h"
#include <cstring>
#include <vector>
#include <iostream>
#include <fstream> // Required for file operations
#include <cstdlib>
#include <algorithm>
#include <cctype>

// Helper function to convert string to lowercase for case-insensitive comparison
std::string to_lower(const std::string& str) {
    std::string result = str;
    std::transform(result.begin(), result.end(), result.begin(), ::tolower);
    return result;
}

// Helper function to get file extension
std::string get_file_extension(const std::string& filename) {
    size_t dot_pos = filename.find_last_of(".");
    if (dot_pos == std::string::npos) {
        return "";
    }
    return to_lower(filename.substr(dot_pos + 1));
}

// Helper function to check if file exists and get size
bool check_file_info(const std::string &fname, size_t& file_size) {
    std::ifstream file(fname, std::ios::binary | std::ios::ate);
    if (!file) {
        std::cerr << "❌ Cannot open file: " << fname << std::endl;
        return false;
    }
    
    file_size = file.tellg();
    std::cerr << "📁 File size: " << file_size << " bytes" << std::endl;
    
    if (file_size == 0) {
        std::cerr << "❌ File is empty: " << fname << std::endl;
        return false;
    }
    
    return true;
}

// Helper function to read audio file into float array
std::vector<float> read_audio_file(const std::string& filename) {
    std::ifstream file(filename, std::ios::binary);
    if (!file.is_open()) {
        std::cerr << "❌ Could not open file: " << filename << std::endl;
        return {};
    }
    
    // Read file size
    file.seekg(0, std::ios::end);
    size_t file_size = file.tellg();
    file.seekg(0, std::ios::beg);
    
    std::cout << "📁 File size: " << file_size << " bytes" << std::endl;
    
    std::string extension = get_file_extension(filename);
    std::cout << "📄 File extension: " << extension << std::endl;
    
    if (extension != "wav") {
        std::cerr << "❌ Unsupported file format: " << extension << " (only WAV supported)" << std::endl;
        return {};
    }
    
    // Read and validate RIFF header
    char riff_header[12];
    file.read(riff_header, 12);
    
    if (std::string(riff_header, 4) != "RIFF") {
        std::cerr << "❌ Invalid RIFF header" << std::endl;
        return {};
    }
    
    if (std::string(riff_header + 8, 4) != "WAVE") {
        std::cerr << "❌ Invalid WAVE header" << std::endl;
        return {};
    }
    
    // Search for fmt chunk (not at fixed offset due to possible JUNK chunks)
    uint16_t audio_format = 0;
    uint16_t num_channels = 0;
    uint32_t sample_rate = 0;
    uint16_t bits_per_sample = 0;
    bool fmt_found = false;
    
    while (file.tellg() < file_size - 8) {
        char chunk_id[4];
        uint32_t chunk_size;
        
        file.read(chunk_id, 4);
        file.read(reinterpret_cast<char*>(&chunk_size), 4);
        
        std::string chunk_name(chunk_id, 4);
        std::cout << "🔍 Found chunk: '" << chunk_name << "' size: " << chunk_size << std::endl;
        
        if (chunk_name == "fmt ") {
            fmt_found = true;
            
            // Read format chunk
            file.read(reinterpret_cast<char*>(&audio_format), 2);
            file.read(reinterpret_cast<char*>(&num_channels), 2);
            file.read(reinterpret_cast<char*>(&sample_rate), 4);
            
            // Skip byte rate and block align
            file.seekg(6, std::ios::cur);
            
            file.read(reinterpret_cast<char*>(&bits_per_sample), 2);
            
            // Skip any remaining format chunk data
            size_t remaining = chunk_size - 16;
            if (remaining > 0) {
                file.seekg(remaining, std::ios::cur);
            }
            
            break;
        } else if (chunk_name == "data") {
            // Found data chunk but no fmt chunk yet - this shouldn't happen
            std::cerr << "❌ Found data chunk before fmt chunk" << std::endl;
            return {};
        } else {
            // Skip unknown chunk (like JUNK)
            std::cout << "⏭️ Skipping chunk: " << chunk_name << std::endl;
            file.seekg(chunk_size, std::ios::cur);
        }
    }
    
    if (!fmt_found) {
        std::cerr << "❌ No fmt chunk found in WAV file" << std::endl;
        return {};
    }
    
    std::cout << "📊 WAV Info:" << std::endl;
    std::cout << "   - Format: " << audio_format << " (1=PCM)" << std::endl;
    std::cout << "   - Channels: " << num_channels << std::endl;
    std::cout << "   - Sample Rate: " << sample_rate << " Hz" << std::endl;
    std::cout << "   - Bits per Sample: " << bits_per_sample << std::endl;
    
    // Validate audio format
    if (audio_format != 1) {
        std::cerr << "❌ Unsupported audio format: " << audio_format << " (only PCM format supported)" << std::endl;
        return {};
    }
    
    if (num_channels != 1) {
        std::cerr << "❌ Whisper requires mono audio (1 channel), got: " << num_channels << std::endl;
        return {};
    }
    
    if (sample_rate != 16000) {
        std::cout << "⚠️ Sample rate is " << sample_rate << "Hz, Whisper expects 16kHz. Audio may not transcribe optimally." << std::endl;
    }
    
    if (bits_per_sample != 16) {
        std::cout << "⚠️ Bit depth is " << bits_per_sample << " bits, expected 16 bits." << std::endl;
    }
    
    // Now search for data chunk
    bool data_found = false;
    uint32_t data_size = 0;
    
    while (file.tellg() < file_size - 8) {
        char chunk_id[4];
        uint32_t chunk_size;
        
        file.read(chunk_id, 4);
        file.read(reinterpret_cast<char*>(&chunk_size), 4);
        
        std::string chunk_name(chunk_id, 4);
        
        if (chunk_name == "data") {
            data_found = true;
            data_size = chunk_size;
            std::cout << "💾 Found data chunk, size: " << data_size << " bytes" << std::endl;
            break;
        } else {
            // Skip chunk
            file.seekg(chunk_size, std::ios::cur);
        }
    }
    
    if (!data_found) {
        std::cerr << "❌ No data chunk found in WAV file" << std::endl;
        return {};
    }
    
    // Read audio data
    size_t num_samples = data_size / (bits_per_sample / 8);
    std::cout << "🎵 Number of samples: " << num_samples << std::endl;
    
    std::vector<float> audio_data;
    audio_data.reserve(num_samples);
    
    if (bits_per_sample == 16) {
        for (size_t i = 0; i < num_samples; ++i) {
            int16_t sample;
            file.read(reinterpret_cast<char*>(&sample), 2);
            // Convert to float [-1.0, 1.0]
            audio_data.push_back(sample / 32768.0f);
        }
    } else {
        std::cerr << "❌ Unsupported bit depth: " << bits_per_sample << std::endl;
        return {};
    }
    
    std::cout << "✅ Successfully read " << audio_data.size() << " audio samples" << std::endl;
    return audio_data;
}

extern "C" {

whisper_context* whisper_ffi_init(const char* model_path) {
    std::cerr << "🤖 Initializing Whisper with model: " << model_path << std::endl;
    try {
        struct whisper_context_params cparams = whisper_context_default_params();
        struct whisper_context* ctx = whisper_init_from_file_with_params(model_path, cparams);
        if (ctx) {
            std::cerr << "✅ Whisper context initialized successfully" << std::endl;
        } else {
            std::cerr << "❌ Failed to initialize Whisper context" << std::endl;
        }
        return ctx;
    } catch (...) {
        std::cerr << "💥 Exception during Whisper initialization" << std::endl;
        return nullptr;
    }
}

char* whisper_ffi_transcribe(whisper_context* ctx, const char* audio_path) {
    std::cerr << "🎵 Starting transcription for: " << audio_path << std::endl;
    
    if (!ctx || !audio_path) {
        std::cerr << "❌ Invalid parameters: ctx=" << (ctx ? "valid" : "null") 
                  << ", audio_path=" << (audio_path ? audio_path : "null") << std::endl;
        return nullptr;
    }
    
    try {
        std::vector<float> pcmf32 = read_audio_file(audio_path);

        if (pcmf32.empty()) {
            std::cerr << "❌ Failed to read audio file: " << audio_path << std::endl;
            return nullptr;
        }

        std::cerr << "⚙️  Configuring Whisper parameters..." << std::endl;
        whisper_full_params wparams = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
        wparams.print_progress = false;
        wparams.print_realtime = false;
        wparams.print_timestamps = false;

        std::cerr << "🔄 Processing audio with Whisper (" << pcmf32.size() << " samples)..." << std::endl;
        if (whisper_full(ctx, wparams, pcmf32.data(), pcmf32.size()) != 0) {
            std::cerr << "❌ Whisper processing failed" << std::endl;
            return nullptr;
        }

        const int n_segments = whisper_full_n_segments(ctx);
        std::cerr << "📝 Extracting " << n_segments << " text segments..." << std::endl;
        
        std::string result_text = "";
        for (int i = 0; i < n_segments; ++i) {
            const char* text = whisper_full_get_segment_text(ctx, i);
            if (text) {
                result_text += text;
            }
        }

        if (result_text.empty()) {
            std::cerr << "⚠️  Warning: Transcription completed but no text extracted" << std::endl;
            result_text = "[No speech detected in audio]";
        }

        std::cerr << "✅ Transcription completed successfully" << std::endl;
        std::cerr << "📄 Result (" << result_text.length() << " chars): " << result_text.substr(0, 100) 
                  << (result_text.length() > 100 ? "..." : "") << std::endl;

        char* result = new char[result_text.length() + 1];
        strcpy(result, result_text.c_str());
        return result;
        
    } catch (...) {
        std::cerr << "💥 Exception during transcription" << std::endl;
        return nullptr;
    }
}

void whisper_ffi_free(whisper_context* ctx) {
    if (ctx) {
        std::cerr << "🧹 Freeing Whisper context" << std::endl;
        whisper_free(ctx);
    }
}

void whisper_ffi_free_string(char* str) {
    if (str) {
        delete[] str; // Use delete[] for memory allocated with new[]
    }
}

}
