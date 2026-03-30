import Foundation
import Testing
@testable import UDDF

struct PerformanceTests {

    func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "uddf")!
        return try Data(contentsOf: url)
    }

    func hardwareInfo() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var cpu = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &cpu, &size, nil, 0)
        let cpuName = String(decoding: cpu.prefix(while: { $0 != 0 }).map(UInt8.init), as: UTF8.self)

        var memSize: UInt64 = 0
        size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &memSize, &size, nil, 0)
        let memGB = memSize / (1024 * 1024 * 1024)

        return "\(cpuName), \(memGB) GB RAM"
    }

    // MARK: - Import Performance

    @Test func importPerf_minimalValid() throws {
        let data = try loadFixture("minimal-valid")
        let iterations = 1000
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try UDDFParser.parse(data: data)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perIteration = elapsed / Double(iterations) * 1000
        print("[\(hardwareInfo())]")
        print("Import minimal-valid (2.5KB): \(String(format: "%.3f", perIteration)) ms/parse (\(iterations) iterations)")
        #expect(perIteration < 10)
    }

    @Test func importPerf_divingLog6Large() throws {
        let data = try loadFixture("divinglog6-mk3i")
        let iterations = 10
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try UDDFParser.parse(data: data)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perIteration = elapsed / Double(iterations) * 1000
        print("[\(hardwareInfo())]")
        print("Import divinglog6 (1.9MB): \(String(format: "%.1f", perIteration)) ms/parse (\(iterations) iterations)")
        #expect(perIteration < 5000) // generous for CI simulator
    }

    // MARK: - Export Performance

    @Test func exportPerf_minimalValid() throws {
        let data = try loadFixture("minimal-valid")
        let doc = try UDDFParser.parse(data: data).document
        let iterations = 1000
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try UDDFExporter.export(document: doc)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perIteration = elapsed / Double(iterations) * 1000
        print("[\(hardwareInfo())]")
        print("Export minimal-valid (2.5KB): \(String(format: "%.3f", perIteration)) ms/export (\(iterations) iterations)")
        #expect(perIteration < 10)
    }

    @Test func exportPerf_divingLog6Large() throws {
        let data = try loadFixture("divinglog6-mk3i")
        let doc = try UDDFParser.parse(data: data).document
        let iterations = 10
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try UDDFExporter.export(document: doc)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perIteration = elapsed / Double(iterations) * 1000
        print("[\(hardwareInfo())]")
        print("Export divinglog6 (1.9MB): \(String(format: "%.1f", perIteration)) ms/export (\(iterations) iterations)")
        #expect(perIteration < 5000) // generous for CI simulator
    }

    // MARK: - Round-Trip Performance

    @Test func roundTripPerf_divingLog6() throws {
        let data = try loadFixture("divinglog6-mk3i")
        let iterations = 5
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            let doc = try UDDFParser.parse(data: data).document
            let exported = try UDDFExporter.export(document: doc)
            _ = try UDDFParser.parse(data: exported)
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        let perIteration = elapsed / Double(iterations) * 1000
        print("[\(hardwareInfo())]")
        print("Round-trip divinglog6 (1.9MB): \(String(format: "%.1f", perIteration)) ms/cycle (\(iterations) iterations)")
        #expect(perIteration < 15000) // generous for CI simulator
    }

    // MARK: - Comparative: XMLDocument (macOS only)

    #if canImport(FoundationXML) || os(macOS)
    @Test func comparative_xmlDocumentParse_large() throws {
        let data = try loadFixture("divinglog6-mk3i")
        let iterations = 10

        // Our parser
        let startOurs = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try UDDFParser.parse(data: data)
        }
        let oursMs = (CFAbsoluteTimeGetCurrent() - startOurs) / Double(iterations) * 1000

        // XMLDocument (Foundation)
        let startXMLDoc = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try XMLDocument(data: data)
        }
        let xmlDocMs = (CFAbsoluteTimeGetCurrent() - startXMLDoc) / Double(iterations) * 1000

        let ratio = oursMs / xmlDocMs
        print("[\(hardwareInfo())]")
        print("Comparative parse (1.9MB, \(iterations) iterations):")
        print("  UDDF (SAX+interpret): \(String(format: "%.1f", oursMs)) ms")
        print("  XMLDocument (DOM):    \(String(format: "%.1f", xmlDocMs)) ms")
        print("  Ratio: \(String(format: "%.2f", ratio))x")
    }

    @Test func comparative_xmlDocumentExport_large() throws {
        let data = try loadFixture("divinglog6-mk3i")
        let doc = try UDDFParser.parse(data: data).document
        let xmlDoc = try XMLDocument(data: data)
        let iterations = 10

        // Our exporter
        let startOurs = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = try UDDFExporter.export(document: doc)
        }
        let oursMs = (CFAbsoluteTimeGetCurrent() - startOurs) / Double(iterations) * 1000

        // XMLDocument serialize
        let startXMLDoc = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            _ = xmlDoc.xmlData(options: .nodePrettyPrint)
        }
        let xmlDocMs = (CFAbsoluteTimeGetCurrent() - startXMLDoc) / Double(iterations) * 1000

        let ratio = oursMs / xmlDocMs
        print("[\(hardwareInfo())]")
        print("Comparative export (1.9MB, \(iterations) iterations):")
        print("  UDDFExporter:       \(String(format: "%.1f", oursMs)) ms")
        print("  XMLDocument.xmlData: \(String(format: "%.1f", xmlDocMs)) ms")
        print("  Ratio: \(String(format: "%.2f", ratio))x")
    }
    #endif
}
