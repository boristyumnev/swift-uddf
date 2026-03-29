import Foundation

/// Parse UDDF (Universal Dive Data Format) files into typed Swift structures.
///
/// Usage:
/// ```swift
/// import UDDF
///
/// let data = try Data(contentsOf: uddfFileURL)
/// let result = try UDDFParser.parse(data: data)
///
/// for dive in result.document.dives {
///     print("Dive at \(dive.datetime ?? "unknown") to \(dive.greatestDepth ?? 0)m")
/// }
/// ```
///
/// The parser auto-detects the generator (Shearwater, Subsurface, etc.)
/// and applies generator-specific interpretation rules.
///
/// All values are in UDDF canonical units:
/// - Depth: meters
/// - Temperature: Kelvin
/// - Pressure: Pascals
/// - Volume: cubic meters
/// - Time: seconds
public enum UDDFParser {

    /// Parse UDDF file data into a typed document.
    ///
    /// - Parameter data: Raw UDDF (XML) file bytes
    /// - Returns: `ParseResult` containing the document and diagnostics
    /// - Throws: `XMLTreeParser.ParseError` on malformed XML
    public static func parse(data: Data) throws -> ParseResult {
        let tree = try XMLTreeParser.parse(data: data)
        let interpreter = InterpreterFactory.interpreter(for: tree)
        return try interpreter.interpret(tree: tree)
    }
}
