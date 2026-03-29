import Foundation

// MARK: - Gas Mix

/// Gas mix definition. N2 is always derived as `1.0 - o2 - he`.
public struct UDDFMix: Codable, Sendable {
    public let id: String
    public let name: String?
    public let o2: Double
    public let he: Double
    public let ar: Double?
    public let h2: Double?

    public init(id: String, name: String? = nil, o2: Double, he: Double = 0, ar: Double? = nil, h2: Double? = nil) {
        self.id = id
        self.name = name
        self.o2 = o2
        self.he = he
        self.ar = ar
        self.h2 = h2
    }
}
