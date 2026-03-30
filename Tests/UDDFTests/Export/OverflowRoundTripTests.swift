import Foundation
import Testing
@testable import UDDF

struct OverflowRoundTripTests {

    // MARK: - Overflow Collection

    @Test func diveOverflow_applicationData() throws {
        // Real Shearwater files have <applicationdata/> which isn't a known child
        let url = Bundle.module.url(forResource: "dive31", withExtension: "uddf")!
        let data = try Data(contentsOf: url)
        let result = try UDDFParser.parse(data: data)
        let dive = result.document.dives[0]
        // applicationdata should be captured as overflow
        let hasAppData = dive.overflow?.contains(where: { $0.name == "applicationdata" })
        #expect(hasAppData == true, "applicationdata should be in dive overflow")
    }

    @Test func overflowCollection_preservesMultipleEntries() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <uddf version="3.2.3">
          <generator><name>Test</name></generator>
          <customext1><data>hello</data></customext1>
          <customext2><data>world</data></customext2>
          <profiledata>
            <repetitiongroup>
              <dive id="d1">
                <informationbeforedive><datetime>2025-01-01T10:00:00Z</datetime></informationbeforedive>
                <informationafterdive><greatestdepth>10</greatestdepth></informationafterdive>
                <vendordata><foo>bar</foo></vendordata>
                <extradata>baz</extradata>
              </dive>
            </repetitiongroup>
          </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        let doc = result.document

        // Root-level overflow: customext1, customext2
        #expect(doc.overflow?.count == 2)
        #expect(doc.overflow?[0].name == "customext1")
        #expect(doc.overflow?[1].name == "customext2")

        // Dive-level overflow: vendordata, extradata
        #expect(doc.dives[0].overflow?.count == 2)
        #expect(doc.dives[0].overflow?[0].name == "vendordata")
        #expect(doc.dives[0].overflow?[1].name == "extradata")
    }

    // MARK: - Overflow Round-Trip

    @Test func overflow_survivesRoundTrip() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <uddf version="3.2.3">
          <generator><name>Test</name></generator>
          <mycustomblock><nested>data</nested></mycustomblock>
          <profiledata>
            <repetitiongroup>
              <dive id="d1">
                <informationbeforedive><datetime>2025-01-01T10:00:00Z</datetime></informationbeforedive>
                <informationafterdive><greatestdepth>10</greatestdepth></informationafterdive>
                <applicationdata><setting key="foo">bar</setting></applicationdata>
              </dive>
            </repetitiongroup>
          </profiledata>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))

        // Export and re-parse
        let exported = try UDDFExporter.export(document: result.document)
        let reparse = try UDDFParser.parse(data: exported)

        // Root-level overflow survived
        #expect(reparse.document.overflow?.count == 1)
        #expect(reparse.document.overflow?[0].name == "mycustomblock")

        // Dive-level overflow survived
        #expect(reparse.document.dives[0].overflow?.count == 1)
        #expect(reparse.document.dives[0].overflow?[0].name == "applicationdata")

        // Known fields unaffected
        #expect(reparse.document.dives[0].greatestDepth == 10)
    }

    @Test func siteOverflow_survivesRoundTrip() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <uddf version="3.2.3">
          <generator><name>Test</name></generator>
          <divesite>
            <site id="s1">
              <name>Test Reef</name>
              <ecology><species>Fish</species></ecology>
            </site>
          </divesite>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        #expect(result.document.sites["s1"]?.overflow?.count == 1)
        #expect(result.document.sites["s1"]?.overflow?[0].name == "ecology")

        let exported = try UDDFExporter.export(document: result.document)
        let reparse = try UDDFParser.parse(data: exported)
        #expect(reparse.document.sites["s1"]?.overflow?[0].name == "ecology")
    }

    @Test func duplicateOverflowNames_preserved() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <uddf version="3.2.3">
          <generator><name>Test</name></generator>
          <extension><a>1</a></extension>
          <extension><b>2</b></extension>
        </uddf>
        """
        let result = try UDDFParser.parse(data: Data(xml.utf8))
        #expect(result.document.overflow?.count == 2)
        #expect(result.document.overflow?[0].name == "extension")
        #expect(result.document.overflow?[1].name == "extension")

        let exported = try UDDFExporter.export(document: result.document)
        let reparse = try UDDFParser.parse(data: exported)
        #expect(reparse.document.overflow?.count == 2)
    }
}
