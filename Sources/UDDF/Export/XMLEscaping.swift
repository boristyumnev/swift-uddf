import Foundation

/// XML 1.0 character validity check.
///
/// Legal characters per XML 1.0 spec (Section 2.2):
/// `#x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]`
func isValidXMLChar(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar.value {
    case 0x9, 0xA, 0xD:
        return true
    case 0x20...0xD7FF:
        return true
    case 0xE000...0xFFFD:
        return true
    case 0x10000...0x10FFFF:
        return true
    default:
        return false
    }
}

/// Strip invalid XML characters from a string.
func stripInvalidXMLChars(_ s: String) -> String {
    String(s.unicodeScalars.filter { isValidXMLChar($0) })
}

/// Escape text content for XML element bodies.
///
/// Escapes `&` (first, to prevent double-escaping), `<`, `>`.
/// Strips characters illegal in XML 1.0.
func escapeText(_ s: String) -> String {
    var result = stripInvalidXMLChars(s)
    result = result.replacingOccurrences(of: "&", with: "&amp;")
    result = result.replacingOccurrences(of: "<", with: "&lt;")
    result = result.replacingOccurrences(of: ">", with: "&gt;")
    return result
}

/// Escape attribute values for XML.
///
/// Escapes everything in `escapeText`, plus `"` and whitespace characters
/// that would be normalized away by XML attribute value normalization
/// (CR → `&#xD;`, LF → `&#xA;`, TAB → `&#x9;`).
func escapeAttribute(_ s: String) -> String {
    var result = escapeText(s)
    result = result.replacingOccurrences(of: "\"", with: "&quot;")
    result = result.replacingOccurrences(of: "\r", with: "&#xD;")
    result = result.replacingOccurrences(of: "\n", with: "&#xA;")
    result = result.replacingOccurrences(of: "\t", with: "&#x9;")
    return result
}
