import Foundation

// MARK: - Parse Result

/// Complete result from interpreting a UDDF file.
public struct ParseResult: Codable, Sendable {
    public let document: UDDFDocument
    public let diagnostics: [ParseDiagnostic]
}

/// A diagnostic message produced during parsing.
public struct ParseDiagnostic: Codable, Sendable {
    public let level: DiagnosticLevel
    public let message: String
    public let context: String?

    public init(level: DiagnosticLevel, message: String, context: String? = nil) {
        self.level = level
        self.message = message
        self.context = context
    }
}

/// Severity of a parse diagnostic.
public enum DiagnosticLevel: String, Codable, Sendable {
    case info
    case warning
    case error
}
