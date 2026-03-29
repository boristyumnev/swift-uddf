import Foundation

/// Protocol for UDDF interpreters. Each implementation handles a specific
/// generator's quirks on top of the standard UDDF spec.
public protocol UDDFInterpreting: Sendable {
    func interpret(tree: XNode) throws -> ParseResult
}

/// Detects the generator from the XML tree and returns the appropriate interpreter.
public enum InterpreterFactory {
    public static func interpreter(for tree: XNode) -> UDDFInterpreting {
        let genName = tree.child("generator")?.stringValue("name")?.lowercased() ?? ""
        if genName.contains("shearwater") {
            return ShearwaterInterpreter()
        }
        if genName.contains("subsurface") {
            return SubsurfaceInterpreter()
        }
        return StandardUDDFInterpreter()
    }
}
