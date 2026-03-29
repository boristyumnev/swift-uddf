import Foundation

// MARK: - UDDF Document

/// Top-level UDDF document, produced by Layer 2 interpretation.
/// All values are in UDDF units (Kelvin, Pascals, cubic meters) — your app converts.
public struct UDDFDocument: Codable, Sendable {
    public let version: String
    public let generator: UDDFGenerator
    public let mixes: [String: UDDFMix]
    public let sites: [String: UDDFSite]
    public let dives: [UDDFDive]
    public let overflow: [String: String]?

    public init(
        version: String,
        generator: UDDFGenerator,
        mixes: [String: UDDFMix],
        sites: [String: UDDFSite],
        dives: [UDDFDive],
        overflow: [String: String]? = nil
    ) {
        self.version = version
        self.generator = generator
        self.mixes = mixes
        self.sites = sites
        self.dives = dives
        self.overflow = overflow
    }
}

// MARK: - Generator

public struct UDDFGenerator: Codable, Sendable {
    public let name: String
    public let version: String?
    public let manufacturer: String?
    public let diveComputer: UDDFDiveComputer?

    public init(name: String, version: String? = nil, manufacturer: String? = nil, diveComputer: UDDFDiveComputer? = nil) {
        self.name = name
        self.version = version
        self.manufacturer = manufacturer
        self.diveComputer = diveComputer
    }
}

public struct UDDFDiveComputer: Codable, Sendable {
    public let name: String?
    public let model: String?
    public let serialNumber: String?

    public init(name: String? = nil, model: String? = nil, serialNumber: String? = nil) {
        self.name = name
        self.model = model
        self.serialNumber = serialNumber
    }
}
