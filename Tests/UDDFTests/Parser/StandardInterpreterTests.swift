import Foundation
import Testing
@testable import UDDF

struct StandardInterpreterTests {

    func parseMinimal() throws -> ParseResult {
        let url = Bundle.module.url(forResource: "minimal-valid", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        return try StandardUDDFInterpreter().interpret(tree: tree)
    }

    // MARK: - Generator

    @Test func generatorParsed() throws {
        let result = try parseMinimal()
        #expect(result.document.generator.name == "TestGenerator")
        #expect(result.document.generator.version == "1.0")
    }

    // MARK: - Version

    @Test func versionParsed() throws {
        let result = try parseMinimal()
        #expect(result.document.version == "3.2.3")
    }

    // MARK: - Mixes

    @Test func mixesParsed() throws {
        let result = try parseMinimal()
        #expect(result.document.mixes.count == 2)

        let air = result.document.mixes["air"]
        #expect(air != nil)
        #expect(air?.o2 == 0.21)
        #expect(air?.he == 0)
        #expect(air?.n2 == 0.79)

        let ean32 = result.document.mixes["ean32"]
        #expect(ean32 != nil)
        #expect(ean32?.o2 == 0.32)
        #expect(ean32?.n2 == 0.68)
    }

    // MARK: - Sites

    @Test func sitesParsed() throws {
        let result = try parseMinimal()
        #expect(result.document.sites.count == 1)

        let site = result.document.sites["site1"]
        #expect(site?.name == "Test Reef")
        #expect(site?.latitude == 47.5)
        #expect(site?.longitude == -122.3)
    }

    // MARK: - Dives

    @Test func diveCount() throws {
        let result = try parseMinimal()
        #expect(result.document.dives.count == 1)
    }

    @Test func diveBeforeInfo() throws {
        let result = try parseMinimal()
        let dive = result.document.dives[0]
        #expect(dive.number == 1)
        #expect(dive.datetime == "2025-06-15T14:30:00Z")
        #expect(dive.surfacePressure == 101325)
        #expect(dive.siteRef == "site1")
    }

    @Test func diveAfterInfo() throws {
        let result = try parseMinimal()
        let dive = result.document.dives[0]
        #expect(dive.greatestDepth == 20.0)
        #expect(dive.averageDepth == 10.0)
        #expect(dive.duration == 240)
    }

    // MARK: - Tank Data

    @Test func tankDataParsed() throws {
        let result = try parseMinimal()
        let dive = result.document.dives[0]
        #expect(dive.tanks.count == 1)
        #expect(dive.tanks[0].mixRef == "air")
        #expect(dive.tanks[0].pressureBegin == 20684000)
        #expect(dive.tanks[0].pressureEnd == 10342000)
    }

    // MARK: - Waypoints

    @Test func waypointCount() throws {
        let result = try parseMinimal()
        #expect(result.document.dives[0].waypoints.count == 5)
    }

    @Test func waypointValues() throws {
        let result = try parseMinimal()
        let wp = result.document.dives[0].waypoints

        // First waypoint
        #expect(wp[0].depth == 0)
        #expect(wp[0].time == 0)
        #expect(wp[0].temperature == 288.15)
        #expect(wp[0].switchMixRef == "air")
        #expect(wp[0].diveMode == .opencircuit)

        // Mid-dive waypoint with PO2 and NDL
        #expect(wp[2].depth == 20.0)
        #expect(wp[2].time == 120)
        // UDDF v3.2.1 spec: calculatedpo2 is in Pa (see calculatedpo2.html).
        #expect(wp[2].calculatedPO2 == 63000)
        #expect(wp[2].ndl == 600)
        #expect(wp[2].tankPressures.first?.value == 17500000)
        #expect(wp[2].tankPressures.first?.ref == "T1")

        // Last waypoint — surface
        #expect(wp[4].depth == 0)
        #expect(wp[4].time == 240)
    }

    // MARK: - Owner, Buddies, DiveBases (minimal has none)

    @Test func minimalHasNoOwnerOrBuddies() throws {
        let result = try parseMinimal()
        #expect(result.document.owner == nil)
        #expect(result.document.buddies.isEmpty)
        #expect(result.document.diveBases.isEmpty)
    }

    // MARK: - Diagnostics

    @Test func diagnosticsIncludeGeneratorInfo() throws {
        let result = try parseMinimal()
        let info = result.diagnostics.first { $0.level == .info }
        #expect(info != nil)
        #expect(info?.message.contains("TestGenerator") == true)
    }
}
