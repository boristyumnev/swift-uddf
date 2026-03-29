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
        #expect(doc.dives[0].waypoints[0].diveMode == .closedcircuit)
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
        #expect(site?.altitude == 0) // altitude is in site/geography

        // First waypoint
        let wp0 = dive.waypoints[0]
        #expect(wp0.depth == 0)
        #expect(wp0.temperature == 287.15)
        #expect(wp0.switchMixRef == "OC1:32/00")
        #expect(wp0.diveMode == .opencircuit)
        #expect(wp0.tankPressures.first?.value != nil)
        #expect(wp0.tankPressures.first?.value != 56247452) // sentinel stripped
        #expect(wp0.tankPressures.first?.ref == "T1")

        // Visibility (Shearwater freeform "40 ft" -> meters)
        #expect(dive.visibility != nil)
        #expect(abs(dive.visibility! - 12.192) < 0.01)

        // Owner + buddy
        #expect(result.document.owner != nil)
        #expect(result.document.owner?.equipment?.diveComputer?.name == "Perdix 2")
        #expect(result.document.buddies.count == 1)
        #expect(result.document.buddies[0].id == "Buddy A")
        #expect(result.document.buddies[0].personal?.firstName == "Buddy A")

        // Mix has n2=nil (Shearwater doesn't include it)
        let mix = result.document.mixes["OC1:32/00"]
        #expect(mix?.n2 == nil)
    }

    @Test func dive105_groundTruth() throws {
        let result = try parseFile("dive105")
        let dive = result.document.dives[0]

        // CCR mix
        #expect(result.document.mixes["CC1:21/00"]?.o2 == 0.21)
        // OC bailout mix
        #expect(result.document.mixes["OC1:32/00"]?.o2 == 0.32)

        // First waypoint is CCR
        #expect(dive.waypoints[0].diveMode == .closedcircuit)
        #expect(dive.waypoints[0].switchMixRef == "CC1:21/00")

        // There's a bailout switch somewhere
        let bailout = dive.waypoints.first { $0.switchMixRef == "OC1:32/00" }
        #expect(bailout != nil)

        // Mode switch diagnostic was emitted
        let modeSwitch = result.diagnostics.first { $0.message.contains("Mode switch") }
        #expect(modeSwitch != nil)

        // Buddy
        #expect(result.document.buddies.count == 1)
        #expect(result.document.buddies[0].id == "Buddy B")
        #expect(result.document.buddies[0].personal?.firstName == "Buddy B")

        // Site density NOT in site data
        let site = result.document.sites.values.first
        #expect(site?.density == nil)
    }

    // MARK: - Synthetic XML: Enum parsing

    @Test func syntheticDiveModeEnum() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <profiledata>
                <repetitiongroup>
                    <dive>
                        <samples>
                            <waypoint>
                                <depth>5</depth><divetime>0</divetime>
                                <divemode type="opencircuit"/>
                            </waypoint>
                            <waypoint>
                                <depth>10</depth><divetime>60</divetime>
                                <divemode type="closedcircuit"/>
                            </waypoint>
                            <waypoint>
                                <depth>8</depth><divetime>120</divetime>
                                <divemode type="semiclosedcircuit"/>
                            </waypoint>
                            <waypoint>
                                <depth>3</depth><divetime>180</divetime>
                                <divemode type="apnea"/>
                            </waypoint>
                        </samples>
                        <informationafterdive><greatestdepth>10</greatestdepth></informationafterdive>
                    </dive>
                </repetitiongroup>
            </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let wps = result.document.dives[0].waypoints
        #expect(wps[0].diveMode == .opencircuit)
        #expect(wps[1].diveMode == .closedcircuit)
        #expect(wps[2].diveMode == .semiclosedcircuit)
        #expect(wps[3].diveMode == .apnea)
    }

    // MARK: - Synthetic XML: Deco Stops

    @Test func syntheticDecoStops() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <profiledata>
                <repetitiongroup>
                    <dive>
                        <samples>
                            <waypoint>
                                <depth>30</depth><divetime>600</divetime>
                                <decostop kind="mandatory" decodepth="6" duration="180"/>
                                <decostop kind="safety" decodepth="3" duration="60"/>
                            </waypoint>
                        </samples>
                        <informationafterdive><greatestdepth>30</greatestdepth></informationafterdive>
                    </dive>
                </repetitiongroup>
            </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let wp = result.document.dives[0].waypoints[0]
        #expect(wp.decoStops.count == 2)
        #expect(wp.decoStops[0].kind == .mandatory)
        #expect(wp.decoStops[0].depth == 6)
        #expect(wp.decoStops[0].duration == 180)
        #expect(wp.decoStops[1].kind == .safety)
        #expect(wp.decoStops[1].depth == 3)
        #expect(wp.decoStops[1].duration == 60)
    }

    // MARK: - Synthetic XML: Alarms

    @Test func syntheticAlarms() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <profiledata>
                <repetitiongroup>
                    <dive>
                        <samples>
                            <waypoint>
                                <depth>25</depth><divetime>300</divetime>
                                <alarm>ascent</alarm>
                                <alarm>deco</alarm>
                            </waypoint>
                        </samples>
                        <informationafterdive><greatestdepth>25</greatestdepth></informationafterdive>
                    </dive>
                </repetitiongroup>
            </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let wp = result.document.dives[0].waypoints[0]
        #expect(wp.alarms.count == 2)
        #expect(wp.alarms[0].type == .ascent)
        #expect(wp.alarms[0].message == "ascent")
        #expect(wp.alarms[1].type == .deco)
        #expect(wp.alarms[1].message == "deco")
    }

    // MARK: - Synthetic XML: Unknown alarm type

    @Test func syntheticUnknownAlarm() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <profiledata>
                <repetitiongroup>
                    <dive>
                        <samples>
                            <waypoint>
                                <depth>20</depth><divetime>200</divetime>
                                <alarm>custom_alarm_xyz</alarm>
                            </waypoint>
                        </samples>
                        <informationafterdive><greatestdepth>20</greatestdepth></informationafterdive>
                    </dive>
                </repetitiongroup>
            </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let wp = result.document.dives[0].waypoints[0]
        #expect(wp.alarms.count == 1)
        #expect(wp.alarms[0].type == nil)
        #expect(wp.alarms[0].message == "custom_alarm_xyz")
    }

    // MARK: - Synthetic XML: Owner + Buddies + DiveBases

    @Test func syntheticOwnerBuddiesDiveBases() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <diver>
                <owner>
                    <personal>
                        <firstname>Jane</firstname>
                        <lastname>Doe</lastname>
                    </personal>
                    <equipment>
                        <divecomputer id="dc1">
                            <name>Perdix</name>
                            <serialnumber>12345</serialnumber>
                        </divecomputer>
                    </equipment>
                </owner>
                <buddy id="b1">
                    <personal><firstname>Bob</firstname></personal>
                </buddy>
                <buddy id="b2">
                    <personal><lastname>Smith</lastname></personal>
                </buddy>
            </diver>
            <divesite>
                <divebase id="base1">
                    <name>Reef Base</name>
                </divebase>
                <site id="s1"><name>Reef</name></site>
            </divesite>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let doc = result.document

        // Owner
        #expect(doc.owner?.personal?.firstName == "Jane")
        #expect(doc.owner?.personal?.lastName == "Doe")
        #expect(doc.owner?.equipment?.diveComputer?.name == "Perdix")
        #expect(doc.owner?.equipment?.diveComputer?.serialNumber == "12345")

        // Buddies
        #expect(doc.buddies.count == 2)
        #expect(doc.buddies[0].id == "b1")
        #expect(doc.buddies[0].personal?.firstName == "Bob")
        #expect(doc.buddies[1].id == "b2")
        #expect(doc.buddies[1].personal?.lastName == "Smith")

        // DiveBases
        #expect(doc.diveBases.count == 1)
        #expect(doc.diveBases[0].id == "base1")
        #expect(doc.diveBases[0].name == "Reef Base")
    }

    // MARK: - Synthetic XML: Surface interval infinity

    @Test func syntheticSurfaceIntervalInfinity() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <profiledata>
                <repetitiongroup>
                    <dive>
                        <informationbeforedive>
                            <surfaceintervalbeforedive><infinity/></surfaceintervalbeforedive>
                        </informationbeforedive>
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
        let dive = result.document.dives[0]
        #expect(dive.surfaceIntervalIsInfinity == true)
        #expect(dive.surfaceInterval == nil)
    }

    // MARK: - Synthetic XML: Tank data with id and breathingConsumptionVolume

    @Test func syntheticTankDataExtendedFields() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <gasdefinitions>
                <mix id="air"><o2>0.21</o2><he>0</he></mix>
            </gasdefinitions>
            <profiledata>
                <repetitiongroup>
                    <dive>
                        <tankdata id="tank1">
                            <link ref="air"/>
                            <tankpressurebegin>20000000</tankpressurebegin>
                            <tankpressureend>10000000</tankpressureend>
                            <tankvolume>0.012</tankvolume>
                            <breathingconsumptionvolume>0.0003</breathingconsumptionvolume>
                        </tankdata>
                        <samples>
                            <waypoint><depth>10</depth><divetime>60</divetime></waypoint>
                        </samples>
                        <informationafterdive><greatestdepth>10</greatestdepth></informationafterdive>
                    </dive>
                </repetitiongroup>
            </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let tank = result.document.dives[0].tanks[0]
        #expect(tank.id == "tank1")
        #expect(tank.mixRef == "air")
        #expect(tank.pressureBegin == 20000000)
        #expect(tank.pressureEnd == 10000000)
        #expect(tank.volume == 0.012)
        #expect(tank.breathingConsumptionVolume == 0.0003)
    }

    // MARK: - Synthetic XML: Generator with type and datetime

    @Test func syntheticGeneratorTypeAndDatetime() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator>
                <name>TestApp</name>
                <type>logbook</type>
                <version>2.0</version>
                <datetime>2025-01-15T10:00:00</datetime>
            </generator>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        #expect(result.document.generator.name == "TestApp")
        #expect(result.document.generator.type == "logbook")
        #expect(result.document.generator.version == "2.0")
        #expect(result.document.generator.datetime == "2025-01-15T10:00:00")
    }

    // MARK: - Synthetic XML: Site with extended fields

    @Test func syntheticSiteExtendedFields() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <divesite>
                <site id="s1">
                    <name>Crystal Lake</name>
                    <environment>lake-quarry</environment>
                    <geography>
                        <location>Pacific Northwest</location>
                        <latitude>47.5</latitude>
                        <longitude>-122.3</longitude>
                    </geography>
                    <sitedata>
                        <maximumdepth>45.0</maximumdepth>
                        <minimumdepth>2.0</minimumdepth>
                        <density>1025</density>
                        <bottom>sandy</bottom>
                    </sitedata>
                    <notes><para>Great viz in summer</para></notes>
                </site>
            </divesite>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let site = result.document.sites["s1"]
        #expect(site?.name == "Crystal Lake")
        #expect(site?.environment == .lakeQuarry)
        #expect(site?.location == "Pacific Northwest")
        #expect(site?.maximumDepth == 45.0)
        #expect(site?.minimumDepth == 2.0)
        #expect(site?.density == 1025)
        #expect(site?.bottom == "sandy")
        #expect(site?.notes == "Great viz in summer")
    }

    // MARK: - Synthetic XML: Mix with n2

    @Test func syntheticMixWithN2() throws {
        let xml = """
        <uddf version="3.2.3">
            <generator><name>Test</name></generator>
            <gasdefinitions>
                <mix id="air">
                    <o2>0.21</o2>
                    <n2>0.79</n2>
                    <he>0</he>
                </mix>
                <mix id="tmx1845">
                    <o2>0.18</o2>
                    <n2>0.37</n2>
                    <he>0.45</he>
                </mix>
            </gasdefinitions>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let air = result.document.mixes["air"]
        #expect(air?.n2 == 0.79)
        let tmx = result.document.mixes["tmx1845"]
        #expect(tmx?.n2 == 0.37)
        #expect(tmx?.he == 0.45)
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
