import Foundation

// MARK: - Site

/// Dive site from `<divesite><site>`.
public struct UDDFSite: Codable, Sendable {
    public let id: String
    public let name: String?
    public let aliasname: String?
    public let environment: UDDFEnvironment?
    // geography
    public let location: String?
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let country: String?
    public let province: String?
    // sitedata
    public let maximumDepth: Double?              // meters
    public let minimumDepth: Double?              // meters
    public let density: Double?                   // kg/m³
    public let bottom: String?
    // rating + notes
    public let rating: Double?
    public let notes: String?
    public let overflow: [UDDFOverflowEntry]?

    public init(
        id: String, name: String? = nil, aliasname: String? = nil,
        environment: UDDFEnvironment? = nil, location: String? = nil,
        latitude: Double? = nil, longitude: Double? = nil,
        altitude: Double? = nil, country: String? = nil, province: String? = nil,
        maximumDepth: Double? = nil, minimumDepth: Double? = nil,
        density: Double? = nil, bottom: String? = nil,
        rating: Double? = nil, notes: String? = nil,
        overflow: [UDDFOverflowEntry]? = nil
    ) {
        self.id = id
        self.name = name
        self.aliasname = aliasname
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
        self.rating = rating
        self.notes = notes
        self.overflow = overflow
    }
}
