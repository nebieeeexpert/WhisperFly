import Foundation

enum PipelineStatus: Sendable, Equatable {
    case idle
    case recording
    case transcribing
    case rewriting
    case pasting
    case error(String)
    
    var isProcessing: Bool {
        switch self {
        case .transcribing, .rewriting, .pasting: return true
        default: return false
        }
    }
    
    var statusText: String {
        switch self {
        case .idle:           return L("status.ready", "Ready")
        case .recording:      return L("status.recording", "Recording…")
        case .transcribing:   return L("status.transcribing", "Transcribing…")
        case .rewriting:      return L("status.rewriting", "Rewriting…")
        case .pasting:        return L("status.pasting", "Pasting…")
        case .error(let msg): return L("status.error", "Error: %@", msg)
        }
    }
    
    var iconName: String {
        switch self {
        case .idle: return "waveform"
        case .recording: return "mic.fill"
        case .transcribing: return "text.bubble"
        case .rewriting: return "sparkles"
        case .pasting: return "doc.on.clipboard"
        case .error: return "exclamationmark.triangle"
        }
    }
}
