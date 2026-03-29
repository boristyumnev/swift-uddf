import Foundation

// MARK: - Owner

/// Diver/owner information from `<diver><owner>`.
public struct UDDFOwner: Codable, Sendable {
    public let personal: UDDFPersonalInfo?
    public let equipment: UDDFEquipmentList?

    public init(personal: UDDFPersonalInfo? = nil, equipment: UDDFEquipmentList? = nil) {
        self.personal = personal
        self.equipment = equipment
    }
}

// MARK: - Buddy

/// Dive buddy from `<diver><buddy>`.
public struct UDDFBuddy: Codable, Sendable {
    public let id: String
    public let personal: UDDFPersonalInfo?

    public init(id: String, personal: UDDFPersonalInfo? = nil) {
        self.id = id
        self.personal = personal
    }
}

// MARK: - Personal Info

/// Personal information from `<personal>` element.
public struct UDDFPersonalInfo: Codable, Sendable {
    public let firstName: String?
    public let middleName: String?
    public let lastName: String?
    public let sex: UDDFSex?
    public let birthdate: String?

    public init(
        firstName: String? = nil, middleName: String? = nil,
        lastName: String? = nil, sex: UDDFSex? = nil,
        birthdate: String? = nil
    ) {
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.sex = sex
        self.birthdate = birthdate
    }
}

// MARK: - Equipment List

/// Equipment list from `<equipment>` — stores dive computer info.
public struct UDDFEquipmentList: Codable, Sendable {
    public let diveComputer: UDDFDiveComputer?

    public init(diveComputer: UDDFDiveComputer? = nil) {
        self.diveComputer = diveComputer
    }
}

// MARK: - Dive Base

/// Dive base/operator from `<divesite><divebase>`.
public struct UDDFDiveBase: Codable, Sendable {
    public let id: String
    public let name: String?

    public init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
}
