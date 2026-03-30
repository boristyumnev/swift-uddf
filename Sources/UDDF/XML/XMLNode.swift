import Foundation

/// A generic XML tree node. No UDDF knowledge — just preserves XML structure.
public struct XNode: Sendable {
    /// Element local name (without namespace prefix).
    public let name: String
    /// Namespace URI, if present.
    public let namespace: String?
    /// All attributes on this element.
    public let attributes: [String: String]
    /// Text content (may include whitespace).
    public var text: String?
    /// Ordered child elements.
    public var children: [XNode]

    public init(
        name: String,
        namespace: String?,
        attributes: [String: String],
        text: String?,
        children: [XNode]
    ) {
        self.name = name
        self.namespace = namespace
        self.attributes = attributes
        self.text = text
        self.children = children
    }
}

// MARK: - Query helpers

extension XNode {
    /// First child with the given name.
    public func child(_ name: String) -> XNode? {
        children.first { $0.name == name }
    }

    /// All children with the given name, preserving order.
    public func children(_ name: String) -> [XNode] {
        children.filter { $0.name == name }
    }

    /// Walk a nested path and return all matches at the leaf.
    ///
    /// Example: `query("profiledata", "repetitiongroup", "dive")` returns
    /// all `<dive>` elements nested at that path.
    public func query(_ path: String...) -> [XNode] {
        queryPath(path[...])
    }

    private func queryPath(_ path: ArraySlice<String>) -> [XNode] {
        guard let first = path.first else { return [self] }
        let rest = path.dropFirst()
        return children(first).flatMap { $0.queryPath(rest) }
    }

    /// Text content trimmed of whitespace and newlines. Nil if empty after trimming.
    public var textValue: String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// Shorthand: get a child's text as Double.
    public func doubleValue(_ childName: String) -> Double? {
        guard let str = child(childName)?.textValue else { return nil }
        return Double(str)
    }

    /// Shorthand: get a child's text as String.
    public func stringValue(_ childName: String) -> String? {
        child(childName)?.textValue
    }

    /// Get an attribute value by name.
    public func attribute(_ name: String) -> String? {
        attributes[name]
    }

    /// Serialize this node and its subtree back to well-formed XML.
    /// Applies proper escaping to text content and attribute values.
    public func toXML(depth: Int = 0) -> String {
        let indent = String(repeating: "  ", count: depth)
        var result = "\(indent)<\(name)"

        // Attributes — sorted for deterministic output
        for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
            result += " \(key)=\"\(escapeAttribute(value))\""
        }

        let hasText = textValue != nil
        let hasChildren = !children.isEmpty

        if !hasText && !hasChildren {
            result += "/>\n"
        } else if hasText && !hasChildren {
            result += ">\(escapeText(text ?? ""))</\(name)>\n"
        } else {
            result += ">\n"
            if let text = textValue {
                result += "\(indent)  \(escapeText(text))\n"
            }
            for child in children {
                result += child.toXML(depth: depth + 1)
            }
            result += "\(indent)</\(name)>\n"
        }

        return result
    }
}
