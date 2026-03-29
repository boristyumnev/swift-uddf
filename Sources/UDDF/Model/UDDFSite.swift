import Foundation

// MARK: - Site

public struct UDDFSite: Codable, Sendable {
    public let id: String
    public let name: String?
    public let location: String?
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let country: String?
    public let province: String?
    public let overflow: [String: String]?

    public init(
        id: String, name: String? = nil, location: String? = nil,
        latitude: Double? = nil, longitude: Double? = nil,
        altitude: Double? = nil, country: String? = nil, province: String? = nil,
        overflow: [String: String]? = nil
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.country = country
        self.province = province
        self.overflow = overflow
    }
}
