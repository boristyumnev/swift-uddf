import Foundation
import Testing
@testable import UDDF

struct ShearwaterInterpreterTests {

    func parseFile(_ name: String) throws -> ParseResult {
        let url = Bundle.module.url(forResource: name, withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        return try ShearwaterInterpreter().interpret(tree: tree)
    }

    // MARK: - Mix ID Parsing

    @Test func extractGasFromCompoundId() {
        let interp = ShearwaterInterpreter()
        let result = interp.extractGasFromId("OC1:32/00")
        #expect(result?.o2 == 0.32)
        #expect(result?.he == 0.0)
    }

    @Test func extractGasFromTrimixId() {
        let interp = ShearwaterInterpreter()
        let result = interp.extractGasFromId("CC1:21/35")
        #expect(result?.o2 == 0.21)
        #expect(result?.he == 0.35)
    }

    @Test func extractGasFromPlainId() {
        let interp = ShearwaterInterpreter()
        let result = interp.extractGasFromId("air")
        #expect(result == nil)
    }

    // MARK: - Mode Inference

    @Test func inferOCMode() {
        let interp = ShearwaterInterpreter()
        #expect(interp.inferDiveMode(from: "OC1:32/00") == "opencircuit")
    }

    @Test func inferCCMode() {
        let interp = ShearwaterInterpreter()
        #expect(interp.inferDiveMode(from: "CC1:21/00") == "closedcircuit")
    }

    @Test func inferModeFromPlainRef() {
        let interp = ShearwaterInterpreter()
        #expect(interp.inferDiveMode(from: "air") == nil)
    }

    // MARK: - Pressure Sentinel

    @Test func cleanPressureSentinel() {
        let interp = ShearwaterInterpreter()
        #expect(interp.cleanPressure(56247452) == nil)
    }

    @Test func cleanPressureNormal() {
        let interp = ShearwaterInterpreter()
        #expect(interp.cleanPressure(20000000) == 20000000)
    }

    // MARK: - Dive31 (OC Dive)

    @Test func dive31_generatorDetected() throws {
        let result = try parseFile("dive31")
        #expect(result.document.generator.name == "Shearwater Cloud Desktop")
        #expect(result.document.generator.diveComputer?.name == "Perdix 2")
    }

    @Test func dive31_mixes() throws {
        let result = try parseFile("dive31")
        #expect(result.document.mixes.count == 1)
        let mix = result.document.mixes["OC1:32/00"]
        #expect(mix?.o2 == 0.32)
        #expect(mix?.he == 0.0)
    }

    @Test func dive31_site() throws {
        let result = try parseFile("dive31")
        #expect(result.document.sites.count == 1)
        let site = result.document.sites.values.first
        #expect(site?.name == "Seacrest Cove 2")
        #expect(site?.latitude == 47.58892)
    }

    @Test func dive31_diveInfo() throws {
        let result = try parseFile("dive31")
        let dive = result.document.dives[0]
        #expect(dive.number == 31)
        #expect(dive.datetime == "2024-07-29T17:44:18Z")
        #expect(dive.greatestDepth == 17.10366)
        #expect(dive.duration == 2231)
        #expect(dive.siteRef == "Seacrest Cove 2 : Alki Beach, WA")
    }

    @Test func dive31_waypointCount() throws {
        let result = try parseFile("dive31")
        #expect(result.document.dives[0].waypoints.count == 226)
    }

    @Test func dive31_firstWaypoint() throws {
        let result = try parseFile("dive31")
        let wp = result.document.dives[0].waypoints[0]
        #expect(wp.depth == 0)
        #expect(wp.time == 0)
        #expect(wp.temperature == 287.15)
        #expect(wp.switchMixRef == "OC1:32/00")
        #expect(wp.diveMode == "opencircuit")
    }

    @Test func dive31_tankPressureSentinelStripped() throws {
        let result = try parseFile("dive31")
        let wp = result.document.dives[0].waypoints[0]
        // T1 should have real pressure, T3/T4 were sentinels — we take T1
        #expect(wp.tankPressure != nil)
        #expect(wp.tankPressure != 56247452)
        #expect(wp.tankRef == "T1")
    }

    @Test func dive31_visibility() throws {
        let result = try parseFile("dive31")
        let dive = result.document.dives[0]
        // "40 ft" → 12.192 meters
        #expect(dive.visibility != nil)
        #expect(abs(dive.visibility! - 12.192) < 0.01)
    }

    // MARK: - Dive105 (CCR Dive)

    @Test func dive105_mixes() throws {
        let result = try parseFile("dive105")
        #expect(result.document.mixes.count == 2)
        #expect(result.document.mixes["CC1:21/00"]?.o2 == 0.21)
        #expect(result.document.mixes["OC1:32/00"]?.o2 == 0.32)
    }

    @Test func dive105_initialModeCCR() throws {
        let result = try parseFile("dive105")
        let firstWp = result.document.dives[0].waypoints[0]
        #expect(firstWp.diveMode == "closedcircuit")
        #expect(firstWp.switchMixRef == "CC1:21/00")
    }

    @Test func dive105_hasBailoutSwitch() throws {
        let result = try parseFile("dive105")
        let waypoints = result.document.dives[0].waypoints

        // Find the waypoint where gas switched to OC1:32/00
        let bailoutWp = waypoints.first { $0.switchMixRef == "OC1:32/00" }
        #expect(bailoutWp != nil)

        // After bailout, subsequent waypoints should be inferred as opencircuit
        if let bailoutIdx = waypoints.firstIndex(where: { $0.switchMixRef == "OC1:32/00" }) {
            let afterBailout = waypoints[bailoutIdx + 1]
            #expect(afterBailout.diveMode == "opencircuit")
        }
    }

    @Test func dive105_visibility() throws {
        let result = try parseFile("dive105")
        let dive = result.document.dives[0]
        // "20 ft" → 6.096 meters
        #expect(dive.visibility != nil)
        #expect(abs(dive.visibility! - 6.096) < 0.01)
    }

    @Test func dive105_diagnosticsIncludeModeSwitch() throws {
        let result = try parseFile("dive105")
        let modeSwitch = result.diagnostics.first {
            $0.message.contains("Mode switch")
        }
        #expect(modeSwitch != nil)
    }

    // MARK: - Generator Detection

    @Test func factorySelectsShearwater() throws {
        let url = Bundle.module.url(forResource: "dive31", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let interpreter = InterpreterFactory.interpreter(for: tree)
        #expect(interpreter is ShearwaterInterpreter)
    }
}
