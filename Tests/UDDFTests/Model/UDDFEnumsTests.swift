import Foundation
import Testing
@testable import UDDF

// MARK: - UDDFDiveMode

struct UDDFDiveModeTests {

    @Test func rawValues() {
        #expect(UDDFDiveMode.apnea.rawValue == "apnea")
        #expect(UDDFDiveMode.opencircuit.rawValue == "opencircuit")
        #expect(UDDFDiveMode.closedcircuit.rawValue == "closedcircuit")
        #expect(UDDFDiveMode.semiclosedcircuit.rawValue == "semiclosedcircuit")
    }

    @Test func initFromRawValue() {
        #expect(UDDFDiveMode(rawValue: "apnea") == .apnea)
        #expect(UDDFDiveMode(rawValue: "opencircuit") == .opencircuit)
        #expect(UDDFDiveMode(rawValue: "closedcircuit") == .closedcircuit)
        #expect(UDDFDiveMode(rawValue: "semiclosedcircuit") == .semiclosedcircuit)
        #expect(UDDFDiveMode(rawValue: "unknown") == nil)
    }

    @Test func codable() throws {
        let mode = UDDFDiveMode.opencircuit
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(UDDFDiveMode.self, from: data)
        #expect(decoded == mode)
    }
}

// MARK: - UDDFApparatus

struct UDDFApparatusTests {

    @Test func rawValues() {
        #expect(UDDFApparatus.openScuba.rawValue == "open-scuba")
        #expect(UDDFApparatus.rebreather.rawValue == "rebreather")
        #expect(UDDFApparatus.surfaceSupplied.rawValue == "surface-supplied")
        #expect(UDDFApparatus.chamber.rawValue == "chamber")
        #expect(UDDFApparatus.experimental.rawValue == "experimental")
        #expect(UDDFApparatus.other.rawValue == "other")
    }

    @Test func initFromRawValue() {
        #expect(UDDFApparatus(rawValue: "open-scuba") == .openScuba)
        #expect(UDDFApparatus(rawValue: "rebreather") == .rebreather)
        #expect(UDDFApparatus(rawValue: "surface-supplied") == .surfaceSupplied)
        #expect(UDDFApparatus(rawValue: "invalid") == nil)
    }

    @Test func codable() throws {
        let value = UDDFApparatus.rebreather
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFApparatus.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFPlatform

struct UDDFPlatformTests {

    @Test func rawValues() {
        #expect(UDDFPlatform.beachShore.rawValue == "beach-shore")
        #expect(UDDFPlatform.pier.rawValue == "pier")
        #expect(UDDFPlatform.smallBoat.rawValue == "small-boat")
        #expect(UDDFPlatform.charterBoat.rawValue == "charter-boat")
        #expect(UDDFPlatform.liveAboard.rawValue == "live-aboard")
        #expect(UDDFPlatform.barge.rawValue == "barge")
        #expect(UDDFPlatform.landside.rawValue == "landside")
        #expect(UDDFPlatform.hyperbaricFacility.rawValue == "hyperbaric-facility")
        #expect(UDDFPlatform.other.rawValue == "other")
    }

    @Test func codable() throws {
        let value = UDDFPlatform.charterBoat
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFPlatform.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFPurpose

struct UDDFPurposeTests {

    @Test func rawValues() {
        #expect(UDDFPurpose.sightseeing.rawValue == "sightseeing")
        #expect(UDDFPurpose.learning.rawValue == "learning")
        #expect(UDDFPurpose.teaching.rawValue == "teaching")
        #expect(UDDFPurpose.research.rawValue == "research")
        #expect(UDDFPurpose.photographyVideography.rawValue == "photography-videography")
        #expect(UDDFPurpose.spearfishing.rawValue == "spearfishing")
        #expect(UDDFPurpose.proficiency.rawValue == "proficiency")
        #expect(UDDFPurpose.work.rawValue == "work")
        #expect(UDDFPurpose.other.rawValue == "other")
    }

    @Test func codable() throws {
        let value = UDDFPurpose.research
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFPurpose.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFCurrent

struct UDDFCurrentTests {

    @Test func rawValues() {
        #expect(UDDFCurrent.noCurrent.rawValue == "no-current")
        #expect(UDDFCurrent.veryMild.rawValue == "very-mild-current")
        #expect(UDDFCurrent.mild.rawValue == "mild-current")
        #expect(UDDFCurrent.moderate.rawValue == "moderate-current")
        #expect(UDDFCurrent.hard.rawValue == "hard-current")
        #expect(UDDFCurrent.veryHard.rawValue == "very-hard-current")
    }

    @Test func codable() throws {
        let value = UDDFCurrent.moderate
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFCurrent.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFThermalComfort

struct UDDFThermalComfortTests {

    @Test func rawValues() {
        #expect(UDDFThermalComfort.notIndicated.rawValue == "not-indicated")
        #expect(UDDFThermalComfort.comfortable.rawValue == "comfortable")
        #expect(UDDFThermalComfort.cold.rawValue == "cold")
        #expect(UDDFThermalComfort.veryCold.rawValue == "very-cold")
        #expect(UDDFThermalComfort.hot.rawValue == "hot")
    }

    @Test func codable() throws {
        let value = UDDFThermalComfort.cold
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFThermalComfort.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFWorkload

struct UDDFWorkloadTests {

    @Test func rawValues() {
        #expect(UDDFWorkload.notSpecified.rawValue == "not-specified")
        #expect(UDDFWorkload.resting.rawValue == "resting")
        #expect(UDDFWorkload.light.rawValue == "light")
        #expect(UDDFWorkload.moderate.rawValue == "moderate")
        #expect(UDDFWorkload.severe.rawValue == "severe")
        #expect(UDDFWorkload.exhausting.rawValue == "exhausting")
    }

    @Test func codable() throws {
        let value = UDDFWorkload.severe
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFWorkload.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFProgram

struct UDDFProgramTests {

    @Test func rawValues() {
        #expect(UDDFProgram.recreation.rawValue == "recreation")
        #expect(UDDFProgram.training.rawValue == "training")
        #expect(UDDFProgram.scientific.rawValue == "scientific")
        #expect(UDDFProgram.medical.rawValue == "medical")
        #expect(UDDFProgram.commercial.rawValue == "commercial")
        #expect(UDDFProgram.military.rawValue == "military")
        #expect(UDDFProgram.competitive.rawValue == "competitive")
        #expect(UDDFProgram.other.rawValue == "other")
    }

    @Test func codable() throws {
        let value = UDDFProgram.scientific
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFProgram.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFStateOfRest

struct UDDFStateOfRestTests {

    @Test func rawValues() {
        #expect(UDDFStateOfRest.notSpecified.rawValue == "not-specified")
        #expect(UDDFStateOfRest.rested.rawValue == "rested")
        #expect(UDDFStateOfRest.tired.rawValue == "tired")
        #expect(UDDFStateOfRest.exhausted.rawValue == "exhausted")
    }

    @Test func codable() throws {
        let value = UDDFStateOfRest.rested
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFStateOfRest.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFEnvironment

struct UDDFEnvironmentTests {

    @Test func rawValues() {
        #expect(UDDFEnvironment.unknown.rawValue == "unknown")
        #expect(UDDFEnvironment.oceanSea.rawValue == "ocean-sea")
        #expect(UDDFEnvironment.lakeQuarry.rawValue == "lake-quarry")
        #expect(UDDFEnvironment.riverSpring.rawValue == "river-spring")
        #expect(UDDFEnvironment.caveCavern.rawValue == "cave-cavern")
        #expect(UDDFEnvironment.pool.rawValue == "pool")
        #expect(UDDFEnvironment.hyperbaricChamber.rawValue == "hyperbaric-chamber")
        #expect(UDDFEnvironment.underIce.rawValue == "under-ice")
        #expect(UDDFEnvironment.other.rawValue == "other")
    }

    @Test func codable() throws {
        let value = UDDFEnvironment.oceanSea
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFEnvironment.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFDecoStopKind

struct UDDFDecoStopKindTests {

    @Test func rawValues() {
        #expect(UDDFDecoStopKind.safety.rawValue == "safety")
        #expect(UDDFDecoStopKind.mandatory.rawValue == "mandatory")
    }

    @Test func initFromRawValue() {
        #expect(UDDFDecoStopKind(rawValue: "safety") == .safety)
        #expect(UDDFDecoStopKind(rawValue: "mandatory") == .mandatory)
        #expect(UDDFDecoStopKind(rawValue: "other") == nil)
    }

    @Test func codable() throws {
        let value = UDDFDecoStopKind.mandatory
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFDecoStopKind.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFSetBySource

struct UDDFSetBySourceTests {

    @Test func rawValues() {
        #expect(UDDFSetBySource.user.rawValue == "user")
        #expect(UDDFSetBySource.computer.rawValue == "computer")
    }

    @Test func codable() throws {
        let value = UDDFSetBySource.computer
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFSetBySource.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFAlarmType

struct UDDFAlarmTypeTests {

    @Test func rawValues() {
        #expect(UDDFAlarmType.ascent.rawValue == "ascent")
        #expect(UDDFAlarmType.breath.rawValue == "breath")
        #expect(UDDFAlarmType.deco.rawValue == "deco")
        #expect(UDDFAlarmType.error.rawValue == "error")
        #expect(UDDFAlarmType.link.rawValue == "link")
        #expect(UDDFAlarmType.microbubbles.rawValue == "microbubbles")
        #expect(UDDFAlarmType.rbt.rawValue == "rbt")
        #expect(UDDFAlarmType.skinCooling.rawValue == "skincooling")
        #expect(UDDFAlarmType.surface.rawValue == "surface")
    }

    @Test func initFromRawValue() {
        #expect(UDDFAlarmType(rawValue: "ascent") == .ascent)
        #expect(UDDFAlarmType(rawValue: "skincooling") == .skinCooling)
        #expect(UDDFAlarmType(rawValue: "unknown_alarm") == nil)
    }

    @Test func codable() throws {
        let value = UDDFAlarmType.deco
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFAlarmType.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - UDDFSex

struct UDDFSexTests {

    @Test func rawValues() {
        #expect(UDDFSex.undetermined.rawValue == "undetermined")
        #expect(UDDFSex.male.rawValue == "male")
        #expect(UDDFSex.female.rawValue == "female")
    }

    @Test func codable() throws {
        let value = UDDFSex.female
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(UDDFSex.self, from: data)
        #expect(decoded == value)
    }
}

// MARK: - DiagnosticLevel

struct DiagnosticLevelTests {

    @Test func rawValues() {
        #expect(DiagnosticLevel.info.rawValue == "info")
        #expect(DiagnosticLevel.warning.rawValue == "warning")
        #expect(DiagnosticLevel.error.rawValue == "error")
    }

    @Test func codable() throws {
        let value = DiagnosticLevel.warning
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(DiagnosticLevel.self, from: data)
        #expect(decoded == value)
    }
}
