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
}
