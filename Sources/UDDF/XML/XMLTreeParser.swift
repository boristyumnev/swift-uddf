import Foundation

/// Parses XML data into a generic `XNode` tree using Foundation's SAX parser.
/// No UDDF knowledge — just preserves XML structure faithfully.
public enum XMLTreeParser {

    public struct ParseError: Error, CustomStringConvertible {
        public let message: String
        public var description: String { message }
    }

    /// Parse XML data into a tree. Throws on malformed XML.
    public static func parse(data: Data) throws -> XNode {
        let delegate = TreeBuilderDelegate()
        let parser = Foundation.XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = true

        guard parser.parse() else {
            let error = delegate.error ?? parser.parserError
            throw ParseError(message: error?.localizedDescription ?? "Unknown XML parse error")
        }

        guard let root = delegate.root else {
            throw ParseError(message: "XML document has no root element")
        }

        return root
    }
}

// MARK: - SAX Delegate

private final class TreeBuilderDelegate: NSObject, XMLParserDelegate {
    var root: XNode?
    var error: Error?

    // Stack of nodes being built. Top of stack = current element.
    private var stack: [XNode] = []
    // Text accumulator for current element
    private var textBuffer = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        // Reset text buffer — any whitespace between tags is discarded
        textBuffer = ""

        let node = XNode(
            name: elementName,
            namespace: namespaceURI,
            attributes: attributes,
            text: nil,
            children: []
        )
        stack.append(node)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        guard var completed = stack.popLast() else { return }

        // Set text if no children (leaf element)
        if completed.children.isEmpty && !textBuffer.isEmpty {
            completed.text = textBuffer
        }
        textBuffer = ""

        if stack.isEmpty {
            // This was the root element
            root = completed
        } else {
            // Add as child to parent
            stack[stack.count - 1].children.append(completed)
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let str = String(data: CDATABlock, encoding: .utf8) {
            textBuffer += str
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        error = parseError
    }

}
