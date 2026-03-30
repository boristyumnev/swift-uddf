import Foundation

/// A single overflow entry — an unrecognized XML element preserved during import.
/// Stored as element name + raw XML fragment for round-trip fidelity.
public struct UDDFOverflowEntry: Codable, Sendable, Equatable {
    /// Element name (e.g. "applicationdata").
    public let name: String
    /// Complete XML fragment including the element itself.
    public let xml: String

    public init(name: String, xml: String) {
        self.name = name
        self.xml = xml
    }
}
