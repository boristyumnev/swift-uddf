import Foundation
import Testing
@testable import UDDF

struct PerformanceTests {

    func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "uddf")!
        return try Data(contentsOf: url)
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
        let perIteration = elapsed / Double(iterations) * 1000 // ms
        print("Import minimal-valid: \(String(format: "%.3f", perIteration)) ms/parse (\(iterations) iterations)")
        // Sanity: should be well under 10ms per parse for 2.5KB
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
        let perIteration = elapsed / Double(iterations) * 1000 // ms
        print("Import divinglog6 (1.9MB): \(String(format: "%.1f", perIteration)) ms/parse (\(iterations) iterations)")
        // Should be under 2 seconds for 1.9MB
        #expect(perIteration < 2000)
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
        let perIteration = elapsed / Double(iterations) * 1000 // ms
        print("Export minimal-valid: \(String(format: "%.3f", perIteration)) ms/export (\(iterations) iterations)")
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
        let perIteration = elapsed / Double(iterations) * 1000 // ms
        print("Export divinglog6 (1.9MB): \(String(format: "%.1f", perIteration)) ms/export (\(iterations) iterations)")
        #expect(perIteration < 2000)
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
        let perIteration = elapsed / Double(iterations) * 1000 // ms
        print("Round-trip divinglog6: \(String(format: "%.1f", perIteration)) ms/cycle (\(iterations) iterations)")
        #expect(perIteration < 5000)
    }
}
