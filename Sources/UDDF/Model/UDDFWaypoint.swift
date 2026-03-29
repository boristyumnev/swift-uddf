import Foundation

// MARK: - Waypoint

public struct UDDFWaypoint: Codable, Sendable {
    public let time: Double
    public let depth: Double
    public let temperature: Double?
    public let tankPressure: Double?
    public let tankRef: String?
    public let switchMixRef: String?
    public let diveMode: String?
    public let calculatedPO2: Double?
    public let measuredPO2: Double?
    public let setPO2: Double?
    public let cns: Double?
    public let ndl: Double?
    public let ceiling: Double?
    public let gradientFactor: Double?
    public let heading: Double?
    public let heartRate: Double?
    public let alarm: String?

    public init(
        time: Double, depth: Double, temperature: Double? = nil,
        tankPressure: Double? = nil, tankRef: String? = nil,
        switchMixRef: String? = nil, diveMode: String? = nil,
        calculatedPO2: Double? = nil, measuredPO2: Double? = nil,
        setPO2: Double? = nil, cns: Double? = nil,
        ndl: Double? = nil, ceiling: Double? = nil,
        gradientFactor: Double? = nil, heading: Double? = nil,
        heartRate: Double? = nil, alarm: String? = nil
    ) {
        self.time = time
        self.depth = depth
        self.temperature = temperature
        self.tankPressure = tankPressure
        self.tankRef = tankRef
        self.switchMixRef = switchMixRef
        self.diveMode = diveMode
        self.calculatedPO2 = calculatedPO2
        self.measuredPO2 = measuredPO2
        self.setPO2 = setPO2
        self.cns = cns
        self.ndl = ndl
        self.ceiling = ceiling
        self.gradientFactor = gradientFactor
        self.heading = heading
        self.heartRate = heartRate
        self.alarm = alarm
    }
}
