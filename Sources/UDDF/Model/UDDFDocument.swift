import Foundation

// MARK: - UDDF Document

/// Top-level UDDF document, produced by Layer 2 interpretation.
/// All values are in UDDF canonical units (Kelvin, Pascals, cubic meters).
public struct UDDFDocument: Codable, Sendable {
    public let version: String
    public let generator: UDDFGenerator
    public let owner: UDDFOwner?
    public let buddies: [UDDFBuddy]
    public let mixes: [String: UDDFMix]
    public let sites: [String: UDDFSite]
    public let diveBases: [UDDFDiveBase]
    public let decoModels: [UDDFDecoModel]
    public let dives: [UDDFDive]
    public let overflow: [String: String]?

    public init(
        version: String,
        generator: UDDFGenerator,
        owner: UDDFOwner? = nil,
        buddies: [UDDFBuddy] = [],
        mixes: [String: UDDFMix] = [:],
        sites: [String: UDDFSite] = [:],
        diveBases: [UDDFDiveBase] = [],
        decoModels: [UDDFDecoModel] = [],
        dives: [UDDFDive] = [],
        overflow: [String: String]? = nil
    ) {
        self.version = version
        self.generator = generator
        self.owner = owner
        self.buddies = buddies
        self.mixes = mixes
        self.sites = sites
        self.diveBases = diveBases
        self.decoModels = decoModels
        self.dives = dives
        self.overflow = overflow
    }
}

// MARK: - Generator

public struct UDDFGenerator: Codable, Sendable {
    public let name: String
    public let type: String?
    public let version: String?
    public let datetime: String?
    public let manufacturer: String?
    public let diveComputer: UDDFDiveComputer?

    public init(
        name: String, type: String? = nil, version: String? = nil,
        datetime: String? = nil, manufacturer: String? = nil,
        diveComputer: UDDFDiveComputer? = nil
    ) {
        self.name = name
        self.type = type
        self.version = version
        self.datetime = datetime
        self.manufacturer = manufacturer
        self.diveComputer = diveComputer
    }
}

public struct UDDFDiveComputer: Codable, Sendable {
    public let name: String?
    public let model: String?
    public let serialNumber: String?
    public let softwareVersion: String?

    public init(
        name: String? = nil, model: String? = nil,
        serialNumber: String? = nil, softwareVersion: String? = nil
    ) {
        self.name = name
        self.model = model
        self.serialNumber = serialNumber
        self.softwareVersion = softwareVersion
    }
}
