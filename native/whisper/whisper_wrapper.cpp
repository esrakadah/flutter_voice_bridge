#include "whisper_wrapper.h"
#include "whisper.h"
#include <cstring>
#include <vector>
#include <iostream>
#include <fstream> // Required for file operations
#include <cstdlib>
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <iterator>

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

namespace {

uint16_t read_le16(const std::vector<uint8_t>& bytes, size_t offset) {
    return static_cast<uint16_t>(bytes[offset] | (bytes[offset + 1] << 8));
}

uint32_t read_le32(const std::vector<uint8_t>& bytes, size_t offset) {
    return static_cast<uint32_t>(bytes[offset]) | (static_cast<uint32_t>(bytes[offset + 1]) << 8) |
           (static_cast<uint32_t>(bytes[offset + 2]) << 16) | (static_cast<uint32_t>(bytes[offset + 3]) << 24);
}

constexpr size_t kRiffHeaderBytes = 12;
constexpr size_t kChunkHeaderBytes = 8;
constexpr size_t kPcmFormatBytes = 16;
constexpr uint16_t kPcmFormat = 1;
constexpr uint16_t kExpectedChannels = 1;
constexpr uint16_t kExpectedBitsPerSample = 16;
constexpr uint32_t kExpectedSampleRate = 16000;
constexpr float kInt16Scale = 32768.0f;

}  // namespace

// Reads a 16-bit mono PCM WAV into floats in [-1, 1]. Every size field is checked against the bytes actually
// present, so a truncated or malformed file returns an empty vector instead of reading past the buffer.
std::vector<float> read_audio_file(const std::string& filename) {
    if (get_file_extension(filename) != "wav") {
        std::cerr << "❌ Only WAV is supported: " << filename << std::endl;
        return {};
    }

    std::ifstream file(filename, std::ios::binary);
    if (!file.is_open()) {
        std::cerr << "❌ Could not open file: " << filename << std::endl;
        return {};
    }
    const std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());

    if (bytes.size() < kRiffHeaderBytes || std::memcmp(bytes.data(), "RIFF", 4) != 0 ||
        std::memcmp(bytes.data() + 8, "WAVE", 4) != 0) {
        std::cerr << "❌ Not a RIFF/WAVE file" << std::endl;
        return {};
    }

    bool format_found = false;
    uint16_t audio_format = 0;
    uint16_t num_channels = 0;
    uint32_t sample_rate = 0;
    uint16_t bits_per_sample = 0;
    size_t data_offset = 0;
    size_t data_size = 0;

    size_t offset = kRiffHeaderBytes;
    while (offset + kChunkHeaderBytes <= bytes.size()) {
        const uint32_t chunk_size = read_le32(bytes, offset + 4);
        const size_t body = offset + kChunkHeaderBytes;
        const size_t available = bytes.size() - body;

        if (std::memcmp(bytes.data() + offset, "fmt ", 4) == 0) {
            if (chunk_size < kPcmFormatBytes || chunk_size > available) {
                std::cerr << "❌ Malformed fmt chunk" << std::endl;
                return {};
            }
            audio_format = read_le16(bytes, body);
            num_channels = read_le16(bytes, body + 2);
            sample_rate = read_le32(bytes, body + 4);
            bits_per_sample = read_le16(bytes, body + 14);
            format_found = true;
        } else if (std::memcmp(bytes.data() + offset, "data", 4) == 0) {
            data_offset = body;
            // Recorders that were stopped abruptly may leave a size larger than the file; use what is there.
            data_size = std::min<size_t>(chunk_size, available);
            break;
        }

        if (chunk_size > available) break;
        offset = body + chunk_size + (chunk_size % 2);  // chunks are padded to an even length
    }

    if (!format_found || data_offset == 0) {
        std::cerr << "❌ WAV is missing its fmt or data chunk" << std::endl;
        return {};
    }
    if (audio_format != kPcmFormat || num_channels != kExpectedChannels || bits_per_sample != kExpectedBitsPerSample) {
        std::cerr << "❌ Need 16-bit mono PCM, got format " << audio_format << ", " << num_channels << " channel(s), "
                  << bits_per_sample << " bits" << std::endl;
        return {};
    }
    if (sample_rate != kExpectedSampleRate) {
        std::cerr << "⚠️ Sample rate is " << sample_rate << " Hz; Whisper expects 16 kHz" << std::endl;
    }

    const size_t sample_count = data_size / sizeof(int16_t);
    std::vector<float> audio(sample_count);
    for (size_t index = 0; index < sample_count; ++index) {
        const auto sample = static_cast<int16_t>(read_le16(bytes, data_offset + index * sizeof(int16_t)));
        audio[index] = sample / kInt16Scale;
    }
    std::cout << "✅ Read " << sample_count << " samples (" << sample_rate << " Hz)" << std::endl;
    return audio;
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

        // An empty string (not a placeholder sentence) lets Dart show "no speech detected" as an error.
        if (result_text.empty()) {
            std::cerr << "⚠️  Warning: Transcription completed but no text extracted" << std::endl;
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
