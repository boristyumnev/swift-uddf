import Foundation

// MARK: - Decompression Model

/// Decompression model definition from `<decomodel>`.
/// Shearwater files reference Buhlmann ZH-L16C with gradient factors.
public struct UDDFDecoModel: Codable, Sendable, Equatable {
    public let id: String
    public let name: String?
    public let gradientFactorHigh: Double?
    public let gradientFactorLow: Double?

    public init(
        id: String, name: String? = nil,
        gradientFactorHigh: Double? = nil,
        gradientFactorLow: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.gradientFactorHigh = gradientFactorHigh
        self.gradientFactorLow = gradientFactorLow
    }
}
