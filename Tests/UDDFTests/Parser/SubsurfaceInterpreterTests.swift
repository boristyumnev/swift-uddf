import Foundation
import Testing
@testable import UDDF

struct SubsurfaceInterpreterTests {

    func parseFile(_ name: String) throws -> ParseResult {
        let url = Bundle.module.url(forResource: name, withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        return try InterpreterFactory.interpreter(for: tree).interpret(tree: tree)
    }

    // MARK: - Subsurface test42

    @Test func subsurface_generatorDetected() throws {
        let url = Bundle.module.url(forResource: "subsurface-test42", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let interpreter = InterpreterFactory.interpreter(for: tree)
        #expect(interpreter is SubsurfaceInterpreter)
    }

    @Test func subsurface_version() throws {
        let result = try parseFile("subsurface-test42")
        #expect(result.document.version == "3.2.0")
    }

    @Test func subsurface_generator() throws {
        let result = try parseFile("subsurface-test42")
        #expect(result.document.generator.name == "Subsurface Divelog")
    }

    @Test func subsurface_threeMixes() throws {
        let result = try parseFile("subsurface-test42")
        #expect(result.document.mixes.count == 3)

        let tmx = result.document.mixes["mix(16/45)"]
        #expect(tmx?.o2 == 0.16)
        #expect(tmx?.he == 0.45)
        #expect(tmx?.name == "TMx 16/45")
        // Subsurface does not include n2 in XML
        #expect(tmx?.n2 == nil)

        let o2 = result.document.mixes["mix(100/0)"]
        #expect(o2?.o2 == 1.0)

        let air = result.document.mixes["mix(21/0)"]
        #expect(air?.o2 == 0.21)
    }

    @Test func subsurface_site() throws {
        let result = try parseFile("subsurface-test42")
        let site = result.document.sites["ec2bbc32"]
        #expect(site != nil)
        #expect(site?.name == "Lake Coleridge")
        #expect(site?.latitude == -43.342295)
        #expect(site?.longitude == 171.545936)
    }

    @Test func subsurface_diveInfo() throws {
        let result = try parseFile("subsurface-test42")
        #expect(result.document.dives.count == 1)
        let dive = result.document.dives[0]
        #expect(dive.number == 1)
        #expect(dive.datetime == "2014-04-02T10:00:00")
        #expect(dive.greatestDepth == 38.99)
        #expect(dive.averageDepth == 17.72)
        #expect(dive.duration == 4674)
    }

    @Test func subsurface_tanks() throws {
        let result = try parseFile("subsurface-test42")
        let tanks = result.document.dives[0].tanks
        #expect(tanks.count == 3)
        #expect(tanks[0].mixRef == "mix(16/45)")
        #expect(tanks[0].volume == 0.002) // cubic meters
        #expect(tanks[0].pressureBegin == 18500000) // pascals
    }

    @Test func subsurface_waypoints() throws {
        let result = try parseFile("subsurface-test42")
        #expect(result.document.dives[0].waypoints.count == 2485)

        let first = result.document.dives[0].waypoints[0]
        #expect(first.depth == 2.34)
        #expect(first.time == 2)
        #expect(first.switchMixRef == "mix(16/45)")
    }

    @Test func subsurface_siteRefResolved() throws {
        let result = try parseFile("subsurface-test42")
        let dive = result.document.dives[0]
        #expect(dive.siteRef != nil)
    }

    // MARK: - Subsurface Divebase

    @Test func subsurface_divebase() throws {
        let result = try parseFile("subsurface-test42")
        #expect(result.document.diveBases.count == 1)
        let base = result.document.diveBases[0]
        #expect(base.id == "allbase")
        #expect(base.name == "Subsurface Divebase")
    }

    // MARK: - Subsurface Buddy

    @Test func subsurface_buddy() throws {
        let result = try parseFile("subsurface-test42")
        #expect(result.document.buddies.count == 1)
        let buddy = result.document.buddies[0]
        #expect(buddy.id == "testbuddyid1")
        #expect(buddy.personal?.firstName == "Buddy C")
    }

    // MARK: - Subsurface Owner (empty names)

    @Test func subsurface_owner() throws {
        let result = try parseFile("subsurface-test42")
        // Owner exists but has empty firstname/lastname
        #expect(result.document.owner != nil)
    }

    // MARK: - Subsurface Air Temperature

    @Test func subsurface_airTemperature() throws {
        let result = try parseFile("subsurface-test42")
        let dive = result.document.dives[0]
        #expect(dive.airTemperature == 285.35)
    }

    // MARK: - Subsurface Rating

    @Test func subsurface_rating() throws {
        let result = try parseFile("subsurface-test42")
        let dive = result.document.dives[0]
        #expect(dive.rating == 8)
    }

    // MARK: - Subsurface Buddy Ref in informationbeforedive

    @Test func subsurface_buddyRefInBeforeDive() throws {
        let result = try parseFile("subsurface-test42")
        let dive = result.document.dives[0]
        // buddyRefs contains link refs from informationbeforedive
        #expect(dive.buddyRefs.contains("testbuddyid1"))
    }
}

// MARK: - AP DiveSight (external generator, standard parser)

struct APDiveSightTests {

    @Test func apdParsesWithoutError() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let interpreter = InterpreterFactory.interpreter(for: tree)
        #expect(interpreter is StandardUDDFInterpreter)
        let result = try interpreter.interpret(tree: tree)
        #expect(result.document.dives.count >= 1)
    }

    @Test func apdVersion() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        #expect(result.document.version == "3.3.0")
    }

    @Test func apdMultipleMixes() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        #expect(result.document.mixes.count >= 4)
    }

    // MARK: - APD Surface Interval Infinity

    @Test func apdSurfaceIntervalInfinity() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        // First dive (previous_dive) has <infinity/>
        let previousDive = result.document.dives.first { $0.id == "previous_dive" }
        #expect(previousDive?.surfaceIntervalIsInfinity == true)
    }

    // MARK: - APD Air Temperature

    @Test func apdAirTemperature() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let dive = result.document.dives.first { $0.id == "dive" }
        #expect(dive?.airTemperature == 290.0)
    }

    // MARK: - APD Highest PO2 and Lowest Temperature

    @Test func apdHighestPO2() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let dive = result.document.dives.first { $0.id == "dive" }
        #expect(dive?.highestPO2 == 154500.0)
    }

    @Test func apdLowestTemperature() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let dive = result.document.dives.first { $0.id == "dive" }
        #expect(dive?.lowestTemperature == 292.6)
    }

    // MARK: - APD Buddy

    @Test func apdBuddy() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        #expect(result.document.buddies.count == 1)
        let buddy = result.document.buddies[0]
        #expect(buddy.id == "buddy1")
        // APD uses lastname, not firstname
        #expect(buddy.personal?.lastName == "Buddy Diver")
    }

    // MARK: - APD Owner

    @Test func apdOwner() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let owner = result.document.owner
        #expect(owner != nil)
        #expect(owner?.personal?.lastName == "Eager Diver")
    }

    // MARK: - APD Mixes with n2 values

    @Test func apdMixesN2Values() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)

        let air = result.document.mixes["diluent_01"]
        #expect(air?.n2 == 0.790)

        let mix20_30 = result.document.mixes["diluent_02"]
        #expect(mix20_30?.n2 == 0.500)
    }

    // MARK: - APD Buddy Ref in informationbeforedive

    @Test func apdBuddyRefInBeforeDive() throws {
        let url = Bundle.module.url(forResource: "apd-inspiration-ccr", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let dive = result.document.dives.first { $0.id == "dive" }
        #expect(dive?.buddyRefs.contains("buddy1") == true)
    }
}

// MARK: - Diving Log 6.0 (external generator, standard parser)

struct DivingLog6Tests {

    @Test func divingLogParsesWithoutError() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        #expect(result.document.dives.count >= 1)
    }

    @Test func divingLogGenerator() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        #expect(result.document.generator.name.contains("Diving Log"))
    }

    // MARK: - Diving Log Lowest Temperature

    @Test func divingLogLowestTemperature() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let dive = result.document.dives[0]
        #expect(dive.lowestTemperature == 302.15)
    }

    // MARK: - Diving Log Rating

    @Test func divingLogRating() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let dive = result.document.dives[0]
        #expect(dive.rating == 0)
    }

    // MARK: - Diving Log Remaining Bottom Time

    @Test func divingLogRemainingBottomTime() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let wp = result.document.dives[0].waypoints[0]
        #expect(wp.remainingBottomTime == 0)
    }

    // MARK: - Diving Log Owner (empty names)

    @Test func divingLogOwnerEmptyNames() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        #expect(result.document.owner != nil)
    }

    // MARK: - Diving Log DecoStops

    @Test func divingLogDecoStops() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let wp = result.document.dives[0].waypoints[0]
        // First waypoint has <decostop kind="safety" decodepth="0" duration="0"/>
        #expect(wp.decoStops.count == 1)
        #expect(wp.decoStops[0].kind == .safety)
        #expect(wp.decoStops[0].depth == 0)
        #expect(wp.decoStops[0].duration == 0)
    }

    // MARK: - Diving Log Multiple Tank Pressures

    @Test func divingLogMultipleTankPressures() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        let wp = result.document.dives[0].waypoints[0]
        // First waypoint has 3 tankpressure elements (ref 1, 2, 3)
        #expect(wp.tankPressures.count == 3)
        #expect(wp.tankPressures[0].ref == "1")
        #expect(wp.tankPressures[1].ref == "2")
        #expect(wp.tankPressures[2].ref == "3")
    }

    // MARK: - Diving Log Generator datetime

    @Test func divingLogGeneratorDatetime() throws {
        let url = Bundle.module.url(forResource: "divinglog6-mk3i", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)
        #expect(result.document.generator.datetime != nil)
        #expect(result.document.generator.datetime?.contains("2024-09-09") == true)
    }
}
