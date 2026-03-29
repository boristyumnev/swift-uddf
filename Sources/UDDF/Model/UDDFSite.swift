import Foundation

// MARK: - Site

/// Dive site from `<divesite><site>`.
public struct UDDFSite: Codable, Sendable {
    public let id: String
    public let name: String?
    public let environment: UDDFEnvironment?
    // geography
    public let location: String?
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let country: String?
    public let province: String?
    // sitedata
    public let maximumDepth: Double?
    public let minimumDepth: Double?
    public let density: Double?
    public let bottom: String?
    // notes
    public let notes: String?
    public let overflow: [String: String]?

    public init(
        id: String, name: String? = nil, environment: UDDFEnvironment? = nil,
        location: String? = nil,
        latitude: Double? = nil, longitude: Double? = nil,
        altitude: Double? = nil, country: String? = nil, province: String? = nil,
        maximumDepth: Double? = nil, minimumDepth: Double? = nil,
        density: Double? = nil, bottom: String? = nil,
        notes: String? = nil, overflow: [String: String]? = nil
    ) {
        self.id = id
        self.name = name
        self.environment = environment
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.country = country
        self.province = province
        self.maximumDepth = maximumDepth
        self.minimumDepth = minimumDepth
        self.density = density
        self.bottom = bottom
        self.notes = notes
        self.overflow = overflow
    }
}
