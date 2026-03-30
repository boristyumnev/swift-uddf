import Foundation

/// Exports a `UDDFDocument` to well-formed UDDF 3.2.3 XML.
///
/// All values are expected in UDDF canonical SI units (meters, Pascals, Kelvin, seconds).
///
/// Usage:
/// ```swift
/// let data = try UDDFExporter.export(document: doc)
/// ```
public enum UDDFExporter {

    /// Export a UDDFDocument to UDDF 3.2.3 XML.
    ///
    /// - Parameters:
    ///   - document: The document to export
    ///   - generator: Generator info identifying the exporting software.
    ///                If nil, uses `document.generator`.
    /// - Returns: UTF-8 encoded XML data
    public static func export(
        document: UDDFDocument,
        generator: UDDFGenerator? = nil
    ) throws -> Data {
        let builder = XMLBuilder()
        let writer = UDDFDocumentWriter()
        writer.write(
            document: document,
            generator: generator ?? document.generator,
            builder: builder
        )
        return builder.build()
    }
}
