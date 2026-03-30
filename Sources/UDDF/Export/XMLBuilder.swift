import Foundation

/// Builds well-formed XML strings with proper escaping and indentation.
///
/// Reference type — closure-based nesting requires shared buffer access.
final class XMLBuilder {
    private var buffer: String = ""
    private var depth: Int = 0
    private let indent: String = "  "

    init() {
        buffer = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
    }

    /// Element with children.
    func element(_ name: String, attributes: [(String, String)] = [], body: () -> Void) {
        appendIndent()
        buffer += "<\(name)"
        appendAttributes(attributes)
        buffer += ">\n"
        depth += 1
        body()
        depth -= 1
        appendIndent()
        buffer += "</\(name)>\n"
    }

    /// Leaf element with text value.
    func element(_ name: String, text: String, attributes: [(String, String)] = []) {
        appendIndent()
        buffer += "<\(name)"
        appendAttributes(attributes)
        buffer += ">\(escapeText(text))</\(name)>\n"
    }

    /// Self-closing element: `<switchmix ref="air"/>`.
    func emptyElement(_ name: String, attributes: [(String, String)] = []) {
        appendIndent()
        buffer += "<\(name)"
        appendAttributes(attributes)
        buffer += "/>\n"
    }

    /// Emit pre-escaped XML verbatim (overflow injection).
    /// The string is indented to the current depth but not escaped.
    func rawXML(_ string: String) {
        let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines {
            appendIndent()
            buffer += line + "\n"
        }
    }

    /// Optional element — emits only if value is non-nil.
    func optionalElement(_ name: String, text: String?) {
        guard let text else { return }
        element(name, text: text)
    }

    /// Optional element for Double values.
    func optionalElement(_ name: String, double: Double?) {
        guard let value = double else { return }
        element(name, text: "\(value)")
    }

    /// Optional element for Int values.
    func optionalElement(_ name: String, int: Int?) {
        guard let value = int else { return }
        element(name, text: "\(value)")
    }

    /// Final output as UTF-8 data.
    func build() -> Data {
        Data(buffer.utf8)
    }

    // MARK: - Private

    private func appendIndent() {
        for _ in 0..<depth {
            buffer += indent
        }
    }

    private func appendAttributes(_ attributes: [(String, String)]) {
        for (key, value) in attributes {
            buffer += " \(key)=\"\(escapeAttribute(value))\""
        }
    }
}
