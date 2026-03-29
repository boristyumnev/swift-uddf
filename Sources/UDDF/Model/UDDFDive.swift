import Foundation

// MARK: - Dive

public struct UDDFDive: Codable, Sendable {
    public let id: String?
    // before
    public let number: Int?
    public let datetime: String?
    public let surfaceInterval: Double?
    public let surfacePressure: Double?
    public let siteRef: String?
    // after
    public let greatestDepth: Double?
    public let averageDepth: Double?
    public let duration: Double?
    public let visibility: Double?
    public let notes: String?
    // tank data
    public let tanks: [UDDFTankData]
    // samples
    public let waypoints: [UDDFWaypoint]
    // overflow (unconsumed elements)
    public let overflow: [String: String]?

    public init(
        id: String? = nil, number: Int? = nil, datetime: String? = nil,
        surfaceInterval: Double? = nil, surfacePressure: Double? = nil,
        siteRef: String? = nil, greatestDepth: Double? = nil,
        averageDepth: Double? = nil, duration: Double? = nil,
        visibility: Double? = nil, notes: String? = nil,
        tanks: [UDDFTankData] = [], waypoints: [UDDFWaypoint] = [],
        overflow: [String: String]? = nil
    ) {
        self.id = id
        self.number = number
        self.datetime = datetime
        self.surfaceInterval = surfaceInterval
        self.surfacePressure = surfacePressure
        self.siteRef = siteRef
        self.greatestDepth = greatestDepth
        self.averageDepth = averageDepth
        self.duration = duration
        self.visibility = visibility
        self.notes = notes
        self.tanks = tanks
        self.waypoints = waypoints
        self.overflow = overflow
    }
}

// MARK: - Tank Data

public struct UDDFTankData: Codable, Sendable {
    public let mixRef: String?
    public let tankRef: String?
    public let pressureBegin: Double?
    public let pressureEnd: Double?
    public let volume: Double?

    public init(
        mixRef: String? = nil, tankRef: String? = nil,
        pressureBegin: Double? = nil, pressureEnd: Double? = nil,
        volume: Double? = nil
    ) {
        self.mixRef = mixRef
        self.tankRef = tankRef
        self.pressureBegin = pressureBegin
        self.pressureEnd = pressureEnd
        self.volume = volume
    }
}
