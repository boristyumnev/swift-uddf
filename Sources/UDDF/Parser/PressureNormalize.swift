import Foundation

/// Normalizes pressure values parsed from UDDF to the SI unit (Pa),
/// fixing exporters that write bar despite the v3.2.1 spec requiring
/// Pascal. Works on value range rather than exporter identity so it
/// catches any broken exporter, not just the one we happen to know
/// about today.
///
/// Known offender: **Shearwater Cloud Desktop**, which writes
/// `<calculatedpo2>0.72</calculatedpo2>` (bar) instead of
/// `<calculatedpo2>72000</calculatedpo2>` (Pa). Other pressure elements
/// in the same file (`tankpressure`, `tankpressurebegin`, `surfacepressure`)
/// are spec-compliant, so the heuristic is scoped to PPO₂ elements.
///
/// Spec references (local mirror: `Documentation/uddf-v3.2.1/`):
/// - calculatedpo2.html — "given in the SI unit _Pascal_ as a real number"
/// - setpo2.html — same
/// - units.html — "All values are given in the SI system"
public enum PressureNormalize {

    /// Physically impossible Pa value for a breathable PPO₂. Anything
    /// below this threshold must be bar. The smallest sensible PPO₂
    /// in real diving is ~0.16 bar (16_000 Pa); 100 Pa is six orders
    /// of magnitude below that — a vacuum. Safe cutoff.
    static let po2BarCutoffPa: Double = 100

    /// Normalize a PPO₂ value (calculatedpo2 / setpo2 / measuredpo2).
    ///
    /// - Parameter value: the raw value as parsed from the XML element.
    /// - Returns: `(normalizedValue, wasNormalized)`. If `wasNormalized`
    ///   is true, the caller should emit a diagnostic so users can see
    ///   which exporter is producing non-compliant files.
    public static func po2(_ value: Double) -> (value: Double, wasNormalized: Bool) {
        if value > 0 && value < po2BarCutoffPa {
            return (value * 100_000, true)
        }
        return (value, false)
    }

    /// Convenience: parse + normalize + emit diagnostic in one step.
    /// Returns the normalized value, or nil if the raw value was nil.
    static func normalizedPO2(
        _ raw: Double?,
        element: String,
        context: String,
        diagnostics: inout [ParseDiagnostic]
    ) -> Double? {
        guard let raw else { return nil }
        let (normalized, wasNormalized) = po2(raw)
        if wasNormalized {
            diagnostics.append(ParseDiagnostic(
                level: .warning,
                message: "<\(element)>\(raw)</\(element)> is non-compliant (UDDF v3.2.1 requires Pa, appears to be bar); normalized to \(normalized) Pa",
                context: context
            ))
        }
        return normalized
    }

    /// Normalize a list of sensor readings (measuredpo2), preserving ref.
    /// Emits one diagnostic per reading that had to be normalized.
    static func normalizedPO2Readings(
        _ readings: [UDDFSensorReading],
        element: String,
        context: String,
        diagnostics: inout [ParseDiagnostic]
    ) -> [UDDFSensorReading] {
        readings.map { reading in
            let (normalized, wasNormalized) = po2(reading.value)
            if wasNormalized {
                diagnostics.append(ParseDiagnostic(
                    level: .warning,
                    message: "<\(element) ref=\"\(reading.ref ?? "")\">\(reading.value)</\(element)> is non-compliant (UDDF v3.2.1 requires Pa, appears to be bar); normalized to \(normalized) Pa",
                    context: context
                ))
            }
            return UDDFSensorReading(ref: reading.ref, value: normalized)
        }
    }
}
