import Foundation

/// Interprets Subsurface UDDF exports with generator-specific overrides.
public struct SubsurfaceInterpreter: UDDFInterpreting, Sendable {

    private let standard = StandardUDDFInterpreter()

    public init() {}

    public func interpret(tree: XNode) throws -> ParseResult {
        // TODO: Override specific parsing methods for Subsurface quirks
        // For now, delegate entirely to standard interpreter
        return try standard.interpret(tree: tree)
    }
}
