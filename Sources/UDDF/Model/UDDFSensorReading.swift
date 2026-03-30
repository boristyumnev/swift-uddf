import Foundation

// MARK: - Sensor Reading

/// A single sensor reading with optional reference identifier.
/// Used for multi-sensor PO2 measurements, battery voltages, and scrubber readings
/// where UDDF allows multiple elements with `ref` attributes per waypoint.
///
/// Examples:
/// - `<measuredpo2 ref="o2sensor_1">130000.0</measuredpo2>` → PO2 in Pascals
/// - `<batteryvoltage ref="battery_1">5.6</batteryvoltage>` → voltage
/// - `<scrubber ref="tempstik">62</scrubber>` → scrubber value
public struct UDDFSensorReading: Codable, Sendable, Equatable {
    /// Reference to sensor id. Nil if only one sensor.
    public let ref: String?
    /// Reading value in canonical units.
    public let value: Double

    public init(ref: String? = nil, value: Double) {
        self.ref = ref
        self.value = value
    }
}
