import Foundation

// MARK: - Owner

/// Diver/owner information from `<diver><owner>`.
public struct UDDFOwner: Codable, Sendable {
    public let personal: UDDFPersonalInfo?
    public let address: UDDFAddress?
    public let contact: UDDFContact?
    public let equipment: UDDFEquipmentList?

    public init(
        personal: UDDFPersonalInfo? = nil,
        address: UDDFAddress? = nil,
        contact: UDDFContact? = nil,
        equipment: UDDFEquipmentList? = nil
    ) {
        self.personal = personal
        self.address = address
        self.contact = contact
        self.equipment = equipment
    }
}

// MARK: - Buddy

/// Dive buddy from `<diver><buddy>`.
public struct UDDFBuddy: Codable, Sendable {
    public let id: String
    public let personal: UDDFPersonalInfo?
    public let address: UDDFAddress?
    public let contact: UDDFContact?

    public init(
        id: String, personal: UDDFPersonalInfo? = nil,
        address: UDDFAddress? = nil, contact: UDDFContact? = nil
    ) {
        self.id = id
        self.personal = personal
        self.address = address
        self.contact = contact
    }
}

// MARK: - Personal Info

/// Personal information from `<personal>` element.
public struct UDDFPersonalInfo: Codable, Sendable {
    public let firstName: String?
    public let middleName: String?
    public let lastName: String?
    public let honorific: String?
    public let sex: UDDFSex?
    public let birthdate: String?
    /// Height in meters.
    public let height: Double?
    /// Weight in kilograms.
    public let weight: Double?
    public let memberships: [UDDFMembership]

    public init(
        firstName: String? = nil, middleName: String? = nil,
        lastName: String? = nil, honorific: String? = nil,
        sex: UDDFSex? = nil, birthdate: String? = nil,
        height: Double? = nil, weight: Double? = nil,
        memberships: [UDDFMembership] = []
    ) {
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.honorific = honorific
        self.sex = sex
        self.birthdate = birthdate
        self.height = height
        self.weight = weight
        self.memberships = memberships
    }
}

// MARK: - Equipment List

/// Equipment list from `<equipment>`.
/// Contains typed equipment items and a convenience accessor for the dive computer.
public struct UDDFEquipmentList: Codable, Sendable {
    /// All equipment items parsed from `<equipment>`.
    public let items: [UDDFEquipmentItem]

    public init(items: [UDDFEquipmentItem] = []) {
        self.items = items
    }

    /// Convenience: first dive computer in the list.
    public var diveComputer: UDDFDiveComputer? {
        guard let item = items.first(where: { $0.type == .divecomputer }) else { return nil }
        return UDDFDiveComputer(
            name: item.name, model: item.model,
            serialNumber: item.serialNumber,
            softwareVersion: item.softwareVersion
        )
    }
}

// MARK: - Dive Base

/// Dive base/operator from `<divesite><divebase>`.
public struct UDDFDiveBase: Codable, Sendable {
    public let id: String
    public let name: String?
    public let address: UDDFAddress?
    public let contact: UDDFContact?
    public let aliasname: String?
    public let rating: Double?
    public let notes: String?

    public init(
        id: String, name: String? = nil,
        address: UDDFAddress? = nil, contact: UDDFContact? = nil,
        aliasname: String? = nil, rating: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.contact = contact
        self.aliasname = aliasname
        self.rating = rating
        self.notes = notes
    }
}
