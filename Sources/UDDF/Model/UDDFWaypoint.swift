import Foundation

// MARK: - Waypoint

/// A single waypoint sample from `<samples><waypoint>`.
public struct UDDFWaypoint: Codable, Sendable {
    /// Dive time in seconds. REQUIRED per spec.
    public let time: Double
    /// Depth in meters. REQUIRED per spec.
    public let depth: Double
    /// Water temperature in Kelvin.
    public let temperature: Double?
    /// Tank pressure readings — one per tank. Spec allows multiple per waypoint.
    public let tankPressures: [UDDFTankPressure]
    /// Gas switch reference from `<switchmix ref="...">`.
    public let switchMixRef: String?
    /// Dive mode from `<divemode type="...">`.
    public let diveMode: UDDFDiveMode?
    /// Calculated partial pressure of O2 in Pascals.
    public let calculatedPO2: Double?
    /// Measured PO2 readings from multiple sensors. Each has a ref and value in Pascals.
    public let measuredPO2s: [UDDFSensorReading]
    /// Rebreather PO2 setpoint in Pascals.
    public let setPO2: Double?
    /// Source of PO2 setpoint (user or computer).
    public let setPO2SetBy: UDDFSetBySource?
    /// CNS O2 toxicity as fraction (0.0–1.0+).
    public let cns: Double?
    /// No-decompression time remaining in seconds.
    public let ndl: Double?
    /// Decompression stops. Spec allows multiple per waypoint.
    public let decoStops: [UDDFDecoStop]
    /// Gradient factor value (current GF).
    public let gradientFactor: Double?
    /// Gradient factor high setting at this waypoint.
    public let setGFHigh: Double?
    /// Gradient factor low setting at this waypoint.
    public let setGFLow: Double?
    /// Time to surface in seconds.
    public let timeToSurface: Double?
    /// Compass heading in degrees.
    public let heading: Double?
    /// Heart rate (beats per minute). Spec uses `<pulserate>` or `<heartrate>`.
    public let heartRate: Double?
    /// Alarms. Spec allows multiple per waypoint.
    public let alarms: [UDDFAlarm]
    /// O2 toxicity units.
    public let otu: Double?
    /// Body temperature in Kelvin.
    public let bodyTemperature: Double?
    /// Battery charge condition as fraction (0.0–1.0).
    public let batteryChargeCondition: Double?
    /// Battery voltage readings from multiple batteries. Each has a ref and value.
    public let batteryVoltages: [UDDFSensorReading]
    /// Scrubber monitor readings. Each has a ref and value.
    public let scrubberReadings: [UDDFSensorReading]
    /// User bookmark marker.
    public let setMarker: Bool?
    /// Remaining bottom time in seconds.
    public let remainingBottomTime: Double?
    /// Remaining O2 time in seconds.
    public let remainingO2Time: Double?

    public init(
        time: Double, depth: Double, temperature: Double? = nil,
        tankPressures: [UDDFTankPressure] = [],
        switchMixRef: String? = nil, diveMode: UDDFDiveMode? = nil,
        calculatedPO2: Double? = nil, measuredPO2s: [UDDFSensorReading] = [],
        setPO2: Double? = nil, setPO2SetBy: UDDFSetBySource? = nil,
        cns: Double? = nil, ndl: Double? = nil,
        decoStops: [UDDFDecoStop] = [],
        gradientFactor: Double? = nil,
        setGFHigh: Double? = nil, setGFLow: Double? = nil,
        timeToSurface: Double? = nil,
        heading: Double? = nil, heartRate: Double? = nil,
        alarms: [UDDFAlarm] = [],
        otu: Double? = nil, bodyTemperature: Double? = nil,
        batteryChargeCondition: Double? = nil,
        batteryVoltages: [UDDFSensorReading] = [],
        scrubberReadings: [UDDFSensorReading] = [],
        setMarker: Bool? = nil,
        remainingBottomTime: Double? = nil, remainingO2Time: Double? = nil
    ) {
        self.time = time
        self.depth = depth
        self.temperature = temperature
        self.tankPressures = tankPressures
        self.switchMixRef = switchMixRef
        self.diveMode = diveMode
        self.calculatedPO2 = calculatedPO2
        self.measuredPO2s = measuredPO2s
        self.setPO2 = setPO2
        self.setPO2SetBy = setPO2SetBy
        self.cns = cns
        self.ndl = ndl
        self.decoStops = decoStops
        self.gradientFactor = gradientFactor
        self.setGFHigh = setGFHigh
        self.setGFLow = setGFLow
        self.timeToSurface = timeToSurface
        self.heading = heading
        self.heartRate = heartRate
        self.alarms = alarms
        self.otu = otu
        self.bodyTemperature = bodyTemperature
        self.batteryChargeCondition = batteryChargeCondition
        self.batteryVoltages = batteryVoltages
        self.scrubberReadings = scrubberReadings
        self.setMarker = setMarker
        self.remainingBottomTime = remainingBottomTime
        self.remainingO2Time = remainingO2Time
    }

    // MARK: - Deprecated backward compatibility

    /// First measured PO2 value. Use `measuredPO2s` array instead.
    @available(*, deprecated, message: "Use measuredPO2s array")
    public var measuredPO2: Double? { measuredPO2s.first?.value }

    /// First tank pressure value. Use `tankPressures` array instead.
    @available(*, deprecated, message: "Use tankPressures array")
    public var tankPressure: Double? { tankPressures.first?.value }

    /// First tank pressure ref. Use `tankPressures[].ref` instead.
    @available(*, deprecated, message: "Use tankPressures[].ref")
    public var tankRef: String? { tankPressures.first?.ref }
}
