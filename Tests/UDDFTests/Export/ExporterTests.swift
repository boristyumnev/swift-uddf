import Foundation
import Testing
@testable import UDDF

struct ExporterTests {

    // MARK: - Basic Export

    @Test func emptyDocument_exportsWellFormedXML() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "TestApp", version: "1.0")
        )
        let data = try UDDFExporter.export(document: doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"utf-8\"?>"))
        #expect(xml.contains("<uddf version=\"3.2.3\">"))
        #expect(xml.contains("<generator>"))
        #expect(xml.contains("<name>TestApp</name>"))
    }

    @Test func exportedXML_isReparseable() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "TestApp", version: "1.0"),
            mixes: ["air": UDDFMix(id: "air", o2: 0.21, he: 0)],
            dives: [UDDFDive(
                id: "d1", number: 1, datetime: "2025-01-01T10:00:00Z",
                greatestDepth: 20.0, duration: 1800,
                waypoints: [
                    UDDFWaypoint(time: 0, depth: 0, switchMixRef: "air", diveMode: .opencircuit),
                    UDDFWaypoint(time: 900, depth: 20),
                    UDDFWaypoint(time: 1800, depth: 0),
                ]
            )]
        )

        let data = try UDDFExporter.export(document: doc)
        let result = try UDDFParser.parse(data: data)
        #expect(result.document.dives.count == 1)
        #expect(result.document.dives[0].waypoints.count == 3)
    }

    // MARK: - Generator

    @Test func generatorOverride() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "OriginalApp")
        )
        let custom = UDDFGenerator(name: "MyExporter", version: "2.0")
        let data = try UDDFExporter.export(document: doc, generator: custom)
        let result = try UDDFParser.parse(data: data)
        #expect(result.document.generator.name == "MyExporter")
        #expect(result.document.generator.version == "2.0")
    }

    @Test func generatorFallback() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "OriginalApp", version: "1.0")
        )
        let data = try UDDFExporter.export(document: doc)
        let result = try UDDFParser.parse(data: data)
        #expect(result.document.generator.name == "OriginalApp")
    }

    // MARK: - Surface Interval

    @Test func surfaceIntervalInfinity() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "Test"),
            dives: [UDDFDive(surfaceIntervalIsInfinity: true)]
        )
        let data = try UDDFExporter.export(document: doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("<infinity/>"))
        #expect(!xml.contains("<passedtime>"))
    }

    @Test func surfaceIntervalPassedTime() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "Test"),
            dives: [UDDFDive(surfaceInterval: 3600)]
        )
        let data = try UDDFExporter.export(document: doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("<passedtime>3600.0</passedtime>"))
    }

    // MARK: - Alarm Precedence

    @Test func alarm_prefersMessage() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "Test"),
            dives: [UDDFDive(waypoints: [
                UDDFWaypoint(time: 0, depth: 10, alarms: [
                    UDDFAlarm(type: .ascent, message: "ascent")
                ])
            ])]
        )
        let data = try UDDFExporter.export(document: doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("<alarm>ascent</alarm>"))
    }

    @Test func alarm_unknownType_usesMessage() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "Test"),
            dives: [UDDFDive(waypoints: [
                UDDFWaypoint(time: 0, depth: 10, alarms: [
                    UDDFAlarm(type: nil, message: "custom-alarm")
                ])
            ])]
        )
        let data = try UDDFExporter.export(document: doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("<alarm>custom-alarm</alarm>"))
    }

    // MARK: - Optional N2

    @Test func mix_nilN2_omitted() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "Test"),
            mixes: ["ean32": UDDFMix(id: "ean32", o2: 0.32, he: 0)]
        )
        let data = try UDDFExporter.export(document: doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(!xml.contains("<n2>"))
    }

    @Test func mix_explicitN2_included() throws {
        let doc = UDDFDocument(
            version: "3.2.3",
            generator: UDDFGenerator(name: "Test"),
            mixes: ["air": UDDFMix(id: "air", o2: 0.21, n2: 0.79, he: 0)]
        )
        let data = try UDDFExporter.export(document: doc)
        let xml = String(data: data, encoding: .utf8)!
        #expect(xml.contains("<n2>0.79</n2>"))
    }
}
