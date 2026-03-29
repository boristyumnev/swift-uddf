import Foundation
import Testing
@testable import UDDF

struct UDDFParserTests {

    func parseFile(_ name: String) throws -> ParseResult {
        let url = Bundle.module.url(forResource: name, withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        return try UDDFParser.parse(data: data)
    }

    // MARK: - Smoke: all files parse without error

    @Test func allTestFilesParse() throws {
        let files = ["dive31", "dive68", "dive105", "minimal-valid",
                     "subsurface-test42", "apd-inspiration-ccr", "divinglog6-mk3i"]
        for name in files {
            let result = try parseFile(name)
            #expect(result.document.dives.count >= 1,
                    "File \(name) should have at least 1 dive")
            #expect(result.diagnostics.contains { $0.level == .info },
                    "File \(name) should have generator info diagnostic")
        }
    }

    // MARK: - Public API: Shearwater OC (dive31)

    @Test func dive31_publicAPI() throws {
        let result = try parseFile("dive31")
        let doc = result.document
        #expect(doc.dives.count == 1)
        #expect(doc.sites.count == 1)
        #expect(doc.dives[0].number == 31)
        #expect(doc.dives[0].waypoints.count == 226)
        #expect(doc.generator.name == "Shearwater Cloud Desktop")
    }

    // MARK: - Public API: Shearwater CCR (dive105)

    @Test func dive105_publicAPI() throws {
        let result = try parseFile("dive105")
        let doc = result.document
        #expect(doc.dives.count == 1)
        #expect(doc.mixes.count == 2)
        #expect(doc.dives[0].waypoints[0].diveMode == "closedcircuit")
    }

    // MARK: - Public API: Subsurface

    @Test func subsurface_publicAPI() throws {
        let result = try parseFile("subsurface-test42")
        let doc = result.document
        #expect(doc.dives.count == 1)
        #expect(doc.generator.name == "Subsurface Divelog")
        #expect(doc.dives[0].duration == 4674)
    }

    // MARK: - Public API: APD Inspiration CCR

    @Test func apdInspiration_publicAPI() throws {
        let result = try parseFile("apd-inspiration-ccr")
        #expect(result.document.dives.count >= 1)
    }

    // MARK: - Public API: Diving Log 6.0

    @Test func divingLog6_publicAPI() throws {
        let result = try parseFile("divinglog6-mk3i")
        #expect(result.document.dives.count >= 1)
    }

    // MARK: - Public API: Minimal valid

    @Test func minimal_publicAPI() throws {
        let result = try parseFile("minimal-valid")
        let doc = result.document
        #expect(doc.version == "3.2.3")
        #expect(doc.mixes.count == 2)
        #expect(doc.sites.count == 1)
        #expect(doc.dives.count == 1)
        #expect(doc.dives[0].waypoints.count == 5)
    }

    // MARK: - Error handling

    @Test func malformedXMLThrows() {
        let bad = Data("<uddf><unclosed>".utf8)
        #expect(throws: Error.self) {
            try UDDFParser.parse(data: bad)
        }
    }

    @Test func emptyDataThrows() {
        #expect(throws: Error.self) {
            try UDDFParser.parse(data: Data())
        }
    }

    // MARK: - Edge cases

    @Test func noProfileDataReturnsEmptyDives() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <gasdefinitions>
                <mix id="air"><o2>0.21</o2><he>0</he></mix>
            </gasdefinitions>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        #expect(result.document.dives.isEmpty)
        #expect(result.document.mixes.count == 1)
    }

    @Test func noMixesStillParsesDives() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <profiledata>
                <repetitiongroup>
                    <dive>
                        <informationbeforedive>
                            <divenumber>1</divenumber>
                        </informationbeforedive>
                        <samples>
                            <waypoint><depth>10</depth><divetime>60</divetime></waypoint>
                        </samples>
                        <informationafterdive>
                            <greatestdepth>10</greatestdepth>
                        </informationafterdive>
                    </dive>
                </repetitiongroup>
            </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        #expect(result.document.dives.count == 1)
        #expect(result.document.mixes.isEmpty)
    }

    @Test func unknownGeneratorFallsBackToStandard() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>FutureDiveApp</name><version>9.0</version></generator>
            <gasdefinitions>
                <mix id="air"><o2>0.21</o2><he>0</he></mix>
            </gasdefinitions>
            <profiledata>
                <repetitiongroup>
                    <dive>
                        <samples>
                            <waypoint><depth>5</depth><divetime>30</divetime></waypoint>
                        </samples>
                        <informationafterdive><greatestdepth>5</greatestdepth></informationafterdive>
                    </dive>
                </repetitiongroup>
            </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        #expect(result.document.dives.count == 1)
        #expect(result.document.generator.name == "FutureDiveApp")
    }

    // MARK: - Ground Truth (specific values from real files)

    @Test func dive31_groundTruth() throws {
        let result = try parseFile("dive31")
        let dive = result.document.dives[0]

        // Dive metadata
        #expect(dive.datetime == "2024-07-29T17:44:18Z")
        #expect(dive.greatestDepth == 17.10366)
        #expect(dive.duration == 2231)

        // Site
        let site = result.document.sites.values.first
        #expect(site?.name == "Seacrest Cove 2")
        #expect(site?.latitude == 47.58892)

        // First waypoint
        let wp0 = dive.waypoints[0]
        #expect(wp0.depth == 0)
        #expect(wp0.temperature == 287.15)
        #expect(wp0.switchMixRef == "OC1:32/00")
        #expect(wp0.diveMode == "opencircuit")
        #expect(wp0.tankPressure != nil)
        #expect(wp0.tankPressure != 56247452) // sentinel stripped

        // Visibility (Shearwater freeform "40 ft" → meters)
        #expect(dive.visibility != nil)
        #expect(abs(dive.visibility! - 12.192) < 0.01)
    }

    @Test func dive105_groundTruth() throws {
        let result = try parseFile("dive105")
        let dive = result.document.dives[0]

        // CCR mix
        #expect(result.document.mixes["CC1:21/00"]?.o2 == 0.21)
        // OC bailout mix
        #expect(result.document.mixes["OC1:32/00"]?.o2 == 0.32)

        // First waypoint is CCR
        #expect(dive.waypoints[0].diveMode == "closedcircuit")
        #expect(dive.waypoints[0].switchMixRef == "CC1:21/00")

        // There's a bailout switch somewhere
        let bailout = dive.waypoints.first { $0.switchMixRef == "OC1:32/00" }
        #expect(bailout != nil)

        // Mode switch diagnostic was emitted
        let modeSwitch = result.diagnostics.first { $0.message.contains("Mode switch") }
        #expect(modeSwitch != nil)
    }
}

// MARK: - InterpreterFactory

struct InterpreterFactoryTests {

    private func tree(generatorName: String) -> XNode {
        XNode(name: "uddf", namespace: nil, attributes: [:], text: nil, children: [
            XNode(name: "generator", namespace: nil, attributes: [:], text: nil, children: [
                XNode(name: "name", namespace: nil, attributes: [:], text: generatorName, children: [])
            ])
        ])
    }

    @Test func selectsShearwater() {
        let interp = InterpreterFactory.interpreter(for: tree(generatorName: "Shearwater Cloud Desktop"))
        #expect(interp is ShearwaterInterpreter)
    }

    @Test func selectsShearwaterCaseInsensitive() {
        let interp = InterpreterFactory.interpreter(for: tree(generatorName: "SHEARWATER Research"))
        #expect(interp is ShearwaterInterpreter)
    }

    @Test func selectsSubsurface() {
        let interp = InterpreterFactory.interpreter(for: tree(generatorName: "Subsurface Divelog"))
        #expect(interp is SubsurfaceInterpreter)
    }

    @Test func selectsStandardForUnknown() {
        let interp = InterpreterFactory.interpreter(for: tree(generatorName: "MacDive"))
        #expect(interp is StandardUDDFInterpreter)
    }

    @Test func selectsStandardForMissingGenerator() {
        let tree = XNode(name: "uddf", namespace: nil, attributes: [:], text: nil, children: [])
        let interp = InterpreterFactory.interpreter(for: tree)
        #expect(interp is StandardUDDFInterpreter)
    }
}
