import Foundation

// Compartilha a persistência; validação e invalidação ficam com cada consumidor.
struct CodableStore<Value: Codable> {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String) {
        self.defaults = defaults
        self.key = key
    }

    func load() throws -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(Value.self, from: data)
    }

    @discardableResult
    func save(_ value: Value) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        defaults.set(data, forKey: key)
        return true
    }

    func remove() {
        defaults.removeObject(forKey: key)
    }
}
