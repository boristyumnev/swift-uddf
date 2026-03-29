import Foundation
import Testing
@testable import UDDF

struct XMLTreeParserTests {

    @Test func parseSimpleXML() throws {
        let xml = """
        <root>
            <child>hello</child>
            <child>world</child>
        </root>
        """
        let tree = try XMLTreeParser.parse(data: Data(xml.utf8))
        #expect(tree.name == "root")
        #expect(tree.children("child").count == 2)
        #expect(tree.children("child")[0].textValue == "hello")
        #expect(tree.children("child")[1].textValue == "world")
    }

    @Test func parseAttributes() throws {
        let xml = """
        <item id="42" type="test">content</item>
        """
        let tree = try XMLTreeParser.parse(data: Data(xml.utf8))
        #expect(tree.attribute("id") == "42")
        #expect(tree.attribute("type") == "test")
        #expect(tree.textValue == "content")
    }

    @Test func parseNamespaces() throws {
        let xml = """
        <uddf xmlns="http://www.streit.cc/uddf/3.2/" version="3.2.3">
            <generator><name>Test</name></generator>
        </uddf>
        """
        let tree = try XMLTreeParser.parse(data: Data(xml.utf8))
        #expect(tree.name == "uddf")
        #expect(tree.namespace == "http://www.streit.cc/uddf/3.2/")
        #expect(tree.attribute("version") == "3.2.3")
        #expect(tree.child("generator")?.stringValue("name") == "Test")
    }

    @Test func parseNestedStructure() throws {
        let xml = """
        <a><b><c>deep</c></b></a>
        """
        let tree = try XMLTreeParser.parse(data: Data(xml.utf8))
        let results = tree.query("b", "c")
        #expect(results.count == 1)
        #expect(results[0].textValue == "deep")
    }

    @Test func parseCDATA() throws {
        let xml = """
        <note><![CDATA[Some <special> text & stuff]]></note>
        """
        let tree = try XMLTreeParser.parse(data: Data(xml.utf8))
        #expect(tree.textValue == "Some <special> text & stuff")
    }

    @Test func parseMalformedXMLThrows() {
        let xml = "<root><unclosed>"
        #expect(throws: Error.self) {
            try XMLTreeParser.parse(data: Data(xml.utf8))
        }
    }

    @Test func parseEmptyElements() throws {
        let xml = """
        <root><empty/><also-empty></also-empty></root>
        """
        let tree = try XMLTreeParser.parse(data: Data(xml.utf8))
        #expect(tree.children.count == 2)
        #expect(tree.child("empty")?.textValue == nil)
        #expect(tree.child("also-empty")?.textValue == nil)
    }

    @Test func parseMixedContent() throws {
        let xml = """
        <root>
            <depth>30.5</depth>
            <temperature>285.15</temperature>
        </root>
        """
        let tree = try XMLTreeParser.parse(data: Data(xml.utf8))
        #expect(tree.doubleValue("depth") == 30.5)
        #expect(tree.doubleValue("temperature") == 285.15)
    }
}
