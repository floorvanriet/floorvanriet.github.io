import Foundation

/// Persisted user preference: which optional strategies to run and in which
/// order. `DirectStrategy` is always appended at the end as a guaranteed
/// fallback and is not part of the persisted list.
public struct UnlockSettings: Codable, Sendable, Equatable {
    public struct Entry: Codable, Sendable, Equatable, Identifiable {
        public var id: String
        public var enabled: Bool
        public init(id: String, enabled: Bool) {
            self.id = id
            self.enabled = enabled
        }
    }

    public var entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }

    public static let `default` = UnlockSettings(entries: [
        Entry(id: "already-archived", enabled: true),
        Entry(id: "archive.is", enabled: true),
        Entry(id: "wayback", enabled: true)
    ])

    /// Display label for the given strategy id.
    public static func displayLabel(for id: String) -> String {
        switch id {
        case "already-archived": return "Al gearchiveerde links direct openen"
        case "archive.is": return "archive.is snapshot"
        case "wayback": return "Wayback Machine"
        case "direct": return "Origineel (reader view)"
        default: return id
        }
    }
}

public protocol SettingsStore: AnyObject {
    func load() -> UnlockSettings
    func save(_ settings: UnlockSettings)
}

public final class UserDefaultsSettingsStore: SettingsStore, @unchecked Sendable {
    public static let appGroupSuite = "group.com.floorvanriet.SuperReader"

    private let defaults: UserDefaults
    private let key = "unlock.settings.v1"

    public init(suiteName: String = UserDefaultsSettingsStore.appGroupSuite) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    public func load() -> UnlockSettings {
        guard
            let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(UnlockSettings.self, from: data)
        else {
            return .default
        }
        return decoded
    }

    public func save(_ settings: UnlockSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
