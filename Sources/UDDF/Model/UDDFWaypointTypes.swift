import Foundation

// MARK: - Tank Pressure

/// A single tank pressure reading from `<tankpressure ref="T1">value</tankpressure>`.
/// UDDF spec allows multiple per waypoint (one per tank).
public struct UDDFTankPressure: Codable, Sendable {
    /// Reference to tank or tankdata id. Nil if only one tank.
    public let ref: String?
    /// Pressure in Pascals.
    public let value: Double

    public init(ref: String? = nil, value: Double) {
        self.ref = ref
        self.value = value
    }
}

// MARK: - Alarm

/// An alarm event from `<alarm>` element in a waypoint.
/// UDDF spec allows multiple alarms per waypoint.
/// Attributes: `level` (real, optional), `tankref` (string, optional).
public struct UDDFAlarm: Codable, Sendable {
    /// Alarm type parsed from element text.
    public let type: UDDFAlarmType?
    /// Raw alarm string for unknown/extension types.
    public let message: String?
    /// Alarm severity level.
    public let level: Double?
    /// Reference to tank that triggered the alarm.
    public let tankRef: String?

    public init(
        type: UDDFAlarmType? = nil, message: String? = nil,
        level: Double? = nil, tankRef: String? = nil
    ) {
        self.type = type
        self.message = message
        self.level = level
        self.tankRef = tankRef
    }
}

// MARK: - Deco Stop

/// A decompression stop from `<decostop>` element.
/// Spec attributes: `kind` (safety|mandatory), `decodepth` (meters), `duration` (seconds).
public struct UDDFDecoStop: Codable, Sendable {
    /// Safety or mandatory stop.
    public let kind: UDDFDecoStopKind?
    /// Stop depth in meters.
    public let depth: Double?
    /// Required stop duration in seconds.
    public let duration: Double?

    public init(kind: UDDFDecoStopKind? = nil, depth: Double? = nil, duration: Double? = nil) {
        self.kind = kind
        self.depth = depth
        self.duration = duration
    }
}
