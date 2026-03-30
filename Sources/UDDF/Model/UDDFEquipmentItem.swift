import Foundation

// MARK: - Equipment Item

/// A single equipment item from `<equipment>`.
/// UDDF defines 20 equipment categories, each sharing common children
/// (name, manufacturer, model, serialnumber, etc.) with type-specific extensions.
public struct UDDFEquipmentItem: Codable, Sendable, Equatable {
    /// Equipment category (boots, fins, tank, suit, divecomputer, etc.).
    public let type: UDDFEquipmentType
    /// UDDF `id` attribute — unique within the file.
    public let id: String
    /// Human-readable name.
    public let name: String?
    /// Manufacturer name.
    public let manufacturer: String?
    /// Model designation.
    public let model: String?
    /// Serial number.
    public let serialNumber: String?
    /// Software version (dive computers).
    public let softwareVersion: String?
    /// Notes.
    public let notes: String?

    // Tank-specific
    /// Tank volume in cubic meters (tanks only). 0.012 m³ = 12 L.
    public let tankVolume: Double?
    /// Tank material (tanks only).
    public let tankMaterial: UDDFTankMaterial?

    // Suit-specific
    /// Suit type (suits only).
    public let suitType: UDDFSuitType?

    public init(
        type: UDDFEquipmentType, id: String,
        name: String? = nil, manufacturer: String? = nil,
        model: String? = nil, serialNumber: String? = nil,
        softwareVersion: String? = nil, notes: String? = nil,
        tankVolume: Double? = nil, tankMaterial: UDDFTankMaterial? = nil,
        suitType: UDDFSuitType? = nil
    ) {
        self.type = type
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
        self.model = model
        self.serialNumber = serialNumber
        self.softwareVersion = softwareVersion
        self.notes = notes
        self.tankVolume = tankVolume
        self.tankMaterial = tankMaterial
        self.suitType = suitType
    }
}
