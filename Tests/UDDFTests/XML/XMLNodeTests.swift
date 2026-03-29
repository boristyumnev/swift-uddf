import Foundation
import Testing
@testable import UDDF

struct XNodeTests {

    // Build a small tree manually for testing query helpers
    static func sampleTree() -> XNode {
        XNode(
            name: "root",
            namespace: nil,
            attributes: ["version": "3.2.3"],
            text: nil,
            children: [
                XNode(name: "generator", namespace: nil, attributes: [:], text: nil, children: [
                    XNode(name: "name", namespace: nil, attributes: [:], text: "TestGen", children: []),
                    XNode(name: "version", namespace: nil, attributes: [:], text: "1.0", children: []),
                ]),
                XNode(name: "items", namespace: nil, attributes: [:], text: nil, children: [
                    XNode(name: "item", namespace: nil, attributes: ["id": "a"], text: nil, children: [
                        XNode(name: "value", namespace: nil, attributes: [:], text: "42.5", children: []),
                    ]),
                    XNode(name: "item", namespace: nil, attributes: ["id": "b"], text: nil, children: [
                        XNode(name: "value", namespace: nil, attributes: [:], text: "99.0", children: []),
                    ]),
                ]),
            ]
        )
    }

    @Test func childByName() {
        let tree = Self.sampleTree()
        let gen = tree.child("generator")
        #expect(gen != nil)
        #expect(gen?.child("name")?.text == "TestGen")
    }

    @Test func childByName_missing() {
        let tree = Self.sampleTree()
        #expect(tree.child("nonexistent") == nil)
    }

    @Test func childrenByName() {
        let tree = Self.sampleTree()
        let items = tree.child("items")?.children("item")
        #expect(items?.count == 2)
        #expect(items?[0].attribute("id") == "a")
        #expect(items?[1].attribute("id") == "b")
    }

    @Test func queryPath() {
        let tree = Self.sampleTree()
        let values = tree.query("items", "item", "value")
        #expect(values.count == 2)
        #expect(values[0].text == "42.5")
        #expect(values[1].text == "99.0")
    }

    @Test func queryPath_noMatch() {
        let tree = Self.sampleTree()
        let results = tree.query("items", "missing", "value")
        #expect(results.isEmpty)
    }

    @Test func doubleValue() {
        let tree = Self.sampleTree()
        let item = tree.child("items")?.children("item").first
        #expect(item?.doubleValue("value") == 42.5)
    }

    @Test func doubleValue_invalidText() {
        let node = XNode(name: "test", namespace: nil, attributes: [:], text: nil, children: [
            XNode(name: "val", namespace: nil, attributes: [:], text: "not a number", children: []),
        ])
        #expect(node.doubleValue("val") == nil)
    }

    @Test func stringValue() {
        let tree = Self.sampleTree()
        let gen = tree.child("generator")
        #expect(gen?.stringValue("name") == "TestGen")
    }

    @Test func attribute() {
        let tree = Self.sampleTree()
        #expect(tree.attribute("version") == "3.2.3")
        #expect(tree.attribute("missing") == nil)
    }

    @Test func textValueTrimsWhitespace() {
        let node = XNode(name: "test", namespace: nil, attributes: [:], text: "  hello  \n", children: [])
        #expect(node.textValue == "hello")
    }

    @Test func textValueNilForEmpty() {
        let node = XNode(name: "test", namespace: nil, attributes: [:], text: "   ", children: [])
        #expect(node.textValue == nil)
    }
}
