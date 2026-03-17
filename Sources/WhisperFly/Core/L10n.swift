import Foundation

/// Resolves localized strings from the SwiftPM module bundle (WhisperFly_WhisperFly.bundle).
/// SwiftPM places resources in a sub-bundle, not in Bundle.main, so we must
/// always pass `bundle: .module` when looking up strings.
func L(_ key: String, _ defaultValue: String = "") -> String {
    Bundle.module.localizedString(forKey: key, value: defaultValue, table: nil)
}

func L(_ key: String, _ defaultValue: String = "", _ args: CVarArg...) -> String {
    String(format: L(key, defaultValue), arguments: args)
}
