import Foundation

struct AppSettings: Codable, Sendable, Equatable {
    enum TranscriptionBackend: String, Codable, Sendable, CaseIterable {
        case groqWhisper = "Groq Whisper (Free)"
        case gemini = "Gemini 2.5 Flash (OpenRouter)"
        // NIM Canary backend removed — use groqWhisper or gemini
    }
    
    enum HotkeyPreset: String, Codable, Sendable, CaseIterable {
        case cmdShiftSpace = "⌘⇧Space"
        case ctrlOptSpace = "⌃⌥Space"
    }
    
    enum AudioSource: String, Codable, Sendable, CaseIterable {
        case microphone = "Microphone"
        case systemAudio = "System Audio"
        
        var localizedName: String {
            switch self {
            case .microphone:  return L("audio_source.microphone", "Microphone")
            case .systemAudio: return L("audio_source.system_audio", "System Audio")
            }
        }
    }
    
    var audioSource: AudioSource = .microphone
    var transcriptionBackend: TranscriptionBackend = .groqWhisper
    var geminiRewriteEnabled: Bool = true
    var rewriteMode: RewriteMode = .cleanup
    var hotkey: HotkeyPreset = .cmdShiftSpace
    var maxRecordingSeconds: Int = 120
    var pasteDelayMs: Int = 120
    var groqApiKey: String = ""
    var openRouterApiKey: String = ""
    var openRouterModel: String = "google/gemini-2.5-flash"
    /// Supported source languages: en, ru, de, fr, es, ja, zh, ko, it, hi
    var sourceLanguage: String = "en"
    var targetLanguage: String = "en"
    var customSystemPrompt: String = ""
    var readAloudEnabled: Bool = false
    
    static let defaults = AppSettings()
}

final class SettingsStore: @unchecked Sendable {
    private let key = "whisperflow_settings"
    
    func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return loadFromEnv()
        }
        return settings
    }
    
    func save(_ settings: AppSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadFromEnv() -> AppSettings {
        var s = AppSettings.defaults
        if let groqKey = Self.readEnvFile()?["GROQ_API_KEY"] {
            s.groqApiKey = groqKey
        }
        if let orKey = Self.readEnvFile()?["OPENROUTER_API_KEY"] {
            s.openRouterApiKey = orKey
        }
        return s
    }
    
    private static func readEnvFile() -> [String: String]? {
        let candidates = [
            Bundle.main.bundlePath + "/../.env",
            FileManager.default.currentDirectoryPath + "/.env"
        ]
        for path in candidates {
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            var dict: [String: String] = [:]
            for line in content.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
                let parts = trimmed.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    dict[String(parts[0])] = String(parts[1])
                }
            }
            return dict
        }
        return nil
    }
}
