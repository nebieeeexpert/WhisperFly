import Foundation
@preconcurrency import AVFoundation

/// Shared utility for converting audio files to 16 kHz mono PCM WAV,
/// which is the format expected by all speech-recognition backends.
enum AudioConverter {
    /// Supported file extensions for the "Transcribe File" picker.
    static let supportedAudioExtensions = ["mp3", "wav", "m4a", "aac", "ogg", "flac", "caf", "aiff", "aif", "wma"]
    static let supportedVideoExtensions = ["mp4", "mov", "mkv", "avi", "webm", "m4v", "ts"]

    /// Extracts the audio track from any media file (audio or video) into a
    /// temporary M4A file that `convertToWAV` can read.
    /// For pure audio files that AVAudioFile can already read, this is a no-op passthrough.
    static func extractAudio(from inputURL: URL) async throws -> URL {
        let ext = inputURL.pathExtension.lowercased()

        // If it's a format AVAudioFile handles natively, skip extraction
        let nativeAudioFormats: Set<String> = ["wav", "caf", "aiff", "aif", "m4a", "mp3", "flac", "aac"]
        if nativeAudioFormats.contains(ext) {
            return inputURL
        }

        // For video files (and exotic audio), use AVAssetExportSession to extract audio → M4A
        let asset = AVAsset(url: inputURL)
        guard try await asset.load(.isReadable) else {
            throw NSError(domain: "WhisperFly", code: 40,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot read media file"])
        }

        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw NSError(domain: "WhisperFly", code: 41,
                          userInfo: [NSLocalizedDescriptionKey: "No audio track found in file"])
        }

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "WhisperFly", code: 42,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot create audio export session"])
        }

        let outputURL = inputURL.deletingPathExtension().appendingPathExtension("extracted.m4a")
        try? FileManager.default.removeItem(at: outputURL)

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        guard exportSession.status == .completed else {
            let msg = exportSession.error?.localizedDescription ?? "Unknown export error"
            throw NSError(domain: "WhisperFly", code: 43,
                          userInfo: [NSLocalizedDescriptionKey: "Audio extraction failed: \(msg)"])
        }

        return outputURL
    }

    static func convertToWAV(_ inputURL: URL) throws -> URL {
        let wavURL = inputURL.deletingPathExtension().appendingPathExtension("wav")
        let inputFile = try AVAudioFile(forReading: inputURL)
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: true
        )!

        let frameCount = AVAudioFrameCount(inputFile.length)
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: inputFile.processingFormat,
            frameCapacity: frameCount
        ) else {
            throw NSError(domain: "WhisperFly", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create input buffer"])
        }
        try inputFile.read(into: inputBuffer)

        let outputBuffer: AVAudioPCMBuffer
        if inputFile.processingFormat == targetFormat {
            outputBuffer = inputBuffer
        } else {
            guard let converter = AVAudioConverter(
                from: inputFile.processingFormat,
                to: targetFormat
            ) else {
                throw NSError(domain: "WhisperFly", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "Audio format conversion not possible"])
            }
            // Calculate correct output frame count when sample rate changes
            let ratio = targetFormat.sampleRate / inputFile.processingFormat.sampleRate
            let outputFrameCapacity = AVAudioFrameCount(ceil(Double(frameCount) * ratio))
            guard let converted = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: outputFrameCapacity
            ) else {
                throw NSError(domain: "WhisperFly", code: 4,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"])
            }
            // Use block-based API for reliable sample rate conversion
            var error: NSError?
            converter.convert(to: converted, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            if let error { throw error }
            outputBuffer = converted
        }

        let outputFile = try AVAudioFile(
            forWriting: wavURL,
            settings: targetFormat.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        )
        try outputFile.write(from: outputBuffer)
        return wavURL
    }
}
