import Foundation

// MARK: - Dive Mode

/// Dive mode from `<divemode type="...">` attribute.
public enum UDDFDiveMode: String, Codable, Sendable {
    case apnea
    case opencircuit
    case closedcircuit
    case semiclosedcircuit
}

// MARK: - Apparatus

/// Diving apparatus from `<apparatus>`.
public enum UDDFApparatus: String, Codable, Sendable {
    case openScuba = "open-scuba"
    case rebreather
    case surfaceSupplied = "surface-supplied"
    case chamber
    case experimental
    case other
}

// MARK: - Platform

/// Dive entry platform from `<platform>`.
public enum UDDFPlatform: String, Codable, Sendable {
    case beachShore = "beach-shore"
    case pier
    case smallBoat = "small-boat"
    case charterBoat = "charter-boat"
    case liveAboard = "live-aboard"
    case barge
    case landside
    case hyperbaricFacility = "hyperbaric-facility"
    case other
}

// MARK: - Purpose

/// Dive purpose from `<purpose>`.
public enum UDDFPurpose: String, Codable, Sendable {
    case sightseeing
    case learning
    case teaching
    case research
    case photographyVideography = "photography-videography"
    case spearfishing
    case proficiency
    case work
    case other
}

// MARK: - Current

/// Water current from `<current>`.
public enum UDDFCurrent: String, Codable, Sendable {
    case noCurrent = "no-current"
    case veryMild = "very-mild-current"
    case mild = "mild-current"
    case moderate = "moderate-current"
    case hard = "hard-current"
    case veryHard = "very-hard-current"
}

// MARK: - Thermal Comfort

/// Thermal comfort from `<thermalcomfort>`.
public enum UDDFThermalComfort: String, Codable, Sendable {
    case notIndicated = "not-indicated"
    case comfortable
    case cold
    case veryCold = "very-cold"
    case hot
}

// MARK: - Workload

/// Dive workload from `<workload>`.
public enum UDDFWorkload: String, Codable, Sendable {
    case notSpecified = "not-specified"
    case resting
    case light
    case moderate
    case severe
    case exhausting
}

// MARK: - Program

/// Dive program from `<program>`.
public enum UDDFProgram: String, Codable, Sendable {
    case recreation
    case training
    case scientific
    case medical
    case commercial
    case military
    case competitive
    case other
}

// MARK: - State of Rest

/// State of rest before dive from `<stateofrestbeforedive>`.
public enum UDDFStateOfRest: String, Codable, Sendable {
    case notSpecified = "not-specified"
    case rested
    case tired
    case exhausted
}

// MARK: - Environment

/// Site environment from `<environment>`.
public enum UDDFEnvironment: String, Codable, Sendable {
    case unknown
    case oceanSea = "ocean-sea"
    case lakeQuarry = "lake-quarry"
    case riverSpring = "river-spring"
    case caveCavern = "cave-cavern"
    case pool
    case hyperbaricChamber = "hyperbaric-chamber"
    case underIce = "under-ice"
    case other
}

// MARK: - Deco Stop Kind

/// Decompression stop kind from `<decostop kind="...">`.
public enum UDDFDecoStopKind: String, Codable, Sendable {
    case safety
    case mandatory
}

// MARK: - SetPO2 Source

/// Source of PO2 setpoint from `<setpo2 setby="...">`.
public enum UDDFSetBySource: String, Codable, Sendable {
    case user
    case computer
}

// MARK: - Alarm Type

/// Alarm type from `<alarm>` element value.
public enum UDDFAlarmType: String, Codable, Sendable {
    case ascent
    case breath
    case deco
    case error
    case link
    case microbubbles
    case rbt
    case skinCooling = "skincooling"
    case surface
}

// MARK: - Sex

/// Biological sex from `<sex>`.
public enum UDDFSex: String, Codable, Sendable {
    case undetermined
    case male
    case female
    case hermaphrodite
}

// MARK: - Equipment Type

/// Equipment category from element name inside `<equipment>`.
public enum UDDFEquipmentType: String, Codable, Sendable {
    case boots
    case buoyancycontroldevice
    case camera
    case compass
    case compressor
    case divecomputer
    case equipmentconfiguration
    case fins
    case gloves
    case knife
    case lead
    case light
    case mask
    case rebreather
    case regulator
    case scooter
    case suit
    case tank
    case variouspieces
    case videocamera
    case watch
}

// MARK: - Suit Type

/// Suit type from `<suittype>`.
public enum UDDFSuitType: String, Codable, Sendable {
    case diveSkin = "dive-skin"
    case wetSuit = "wet-suit"
    case drySuit = "dry-suit"
    case hotWaterSuit = "hot-water-suit"
    case other
}

// MARK: - Tank Material

/// Tank material from `<tankmaterial>`.
public enum UDDFTankMaterial: String, Codable, Sendable {
    case aluminium
    case carbon
    case steel
}
