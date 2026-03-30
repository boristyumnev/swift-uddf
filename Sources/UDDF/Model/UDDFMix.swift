import Foundation

// MARK: - Gas Mix

/// Gas mix definition from `<gasdefinitions><mix>`.
/// All fractions are 0.0–1.0 and should sum to 1.0.
public struct UDDFMix: Codable, Sendable {
    public let id: String
    public let name: String?
    public let o2: Double
    public let n2: Double?
    public let he: Double
    public let ar: Double?
    public let h2: Double?
    /// Maximum PO2 in Pascals (some generators emit `<maximumpo2>`).
    public let maximumPO2: Double?
    /// Maximum operation depth in meters (some generators emit `<maximumoperationdepth>`).
    public let maximumOperationDepth: Double?

    public init(
        id: String, name: String? = nil, o2: Double,
        n2: Double? = nil, he: Double = 0,
        ar: Double? = nil, h2: Double? = nil,
        maximumPO2: Double? = nil, maximumOperationDepth: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.o2 = o2
        self.n2 = n2
        self.he = he
        self.ar = ar
        self.h2 = h2
        self.maximumPO2 = maximumPO2
        self.maximumOperationDepth = maximumOperationDepth
    }
}
