# UDDF Export + Overflow Round-Trip — Design Spec

## Overview

Add UDDF 3.2.3 XML export capability to the swift-uddf library, plus overflow collection during import. Together these enable full round-trip fidelity: parse a UDDF file, export it, re-parse — identical data.

## Scope

- XML export from `UDDFDocument` to well-formed UDDF 3.2.3 XML
- Overflow collection during import (capture unrecognized XML elements)
- Overflow splicing during export (re-insert captured elements)
- Internal XML builder with correct XML 1.0 escaping
- Performance measurement tests for import and export
- Zero new dependencies (Foundation only)

## Public API

```swift
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
    ) throws -> Data
}
```

The existing parse API is unchanged:

```swift
let result = try UDDFParser.parse(data: data)
let exported = try UDDFExporter.export(document: result.document)
```

## Architecture

### File Structure

```
Sources/UDDF/
  Export/
    UDDFExporter.swift          — public entry point
    UDDFDocumentWriter.swift    — walks model tree, emits elements in spec order
    XMLBuilder.swift            — renders XML (escaping, indentation, nesting)
    XMLEscaping.swift           — escaping functions + valid char check
```

### XML Builder (Internal)

A string buffer with helpers for building well-formed XML:

```swift
struct XMLBuilder {
    /// Element with children.
    func element(_ name: String, attributes: [(String, String)] = [], body: () -> Void)

    /// Leaf element with text value.
    func element(_ name: String, text: String, attributes: [(String, String)] = [])

    /// Self-closing element: <switchmix ref="air"/>
    func emptyElement(_ name: String, attributes: [(String, String)] = [])

    /// Emit pre-escaped XML verbatim (overflow injection).
    func rawXML(_ string: String)

    /// Final output — UTF-8 with <?xml version="1.0" encoding="utf-8"?> header.
    func build() -> Data
}
```

Formatting: 2-space indentation, one element per line.

### XML Escaping

Two functions following Go's `encoding/xml` approach (the most thorough of the production libraries surveyed):

**`escapeText(_ s: String) -> String`**

| Character | Replacement |
|-----------|-------------|
| `&` | `&amp;` (always first to prevent double-escaping) |
| `<` | `&lt;` |
| `>` | `&gt;` |
| Invalid XML chars | stripped |

**`escapeAttribute(_ s: String) -> String`**

Everything in `escapeText`, plus:

| Character | Replacement |
|-----------|-------------|
| `"` | `&quot;` |
| CR (U+000D) | `&#xD;` |
| LF (U+000A) | `&#xA;` |
| TAB (U+0009) | `&#x9;` |

**`isValidXMLChar(_ scalar: Unicode.Scalar) -> Bool`**

XML 1.0 `Char` production:
```
U+0009 | U+000A | U+000D | U+0020–U+D7FF | U+E000–U+FFFD | U+10000–U+10FFFF
```

Everything else (null, C0 controls 0x01–0x08/0x0B/0x0C/0x0E–0x1F, surrogates, U+FFFE/FFFF) is stripped from output.

### Escaping rationale

Surveyed four production XML libraries:

| Library | Text chars | Attr chars | Whitespace in attrs | Invalid Unicode |
|---------|-----------|-----------|-------------------|-----------------|
| Python `saxutils` | 3 (`&<>`) | +`"` | `\t\n\r` escaped | no handling |
| Go `encoding/xml` | 3 (`&<>`) | +`"'` | `\t\n\r` escaped | replace with U+FFFD |
| Java `XMLStreamWriter` | 3 (`&<>`) | +`"` | no handling | numeric refs |
| Swift XMLCoder | 5 (`&<>"'`) | same | no handling | no handling |

We follow Go's approach: most thorough, handles whitespace normalization in attributes (which Python also catches but Java and XMLCoder miss), and sanitizes invalid Unicode.

### Document Writer (Internal)

Walks the model tree emitting elements in UDDF 3.2.3 spec order:

```swift
struct UDDFDocumentWriter {
    func write(document: UDDFDocument, generator: UDDFGenerator, builder: XMLBuilder)
}
```

Element ordering per spec:

1. `<generator>` — name, type, version, datetime, manufacturer
2. `<gasdefinitions>` — mix elements
3. `<diver>` — owner (personal, address, contact, equipment), buddies
4. `<divesite>` — divebases, then sites
5. `<decomodel>` — Buhlmann GF
6. `<profiledata>` — repetition groups containing dives
7. Root-level overflow (unrecognized elements from `document.overflow`)

Each section is a method: `writeGenerator()`, `writeMixes()`, `writeDiver()`, `writeSites()`, `writeDecoModels()`, `writeDives()`.

Within `<dive>`:
1. `<informationbeforedive>` — all before-dive fields
2. `<tankdata>` elements
3. `<samples>` — waypoint elements
4. `<informationafterdive>` — all after-dive fields
5. Dive-level overflow

## Overflow Design

### Collection (Import Side)

Add a helper to `StandardUDDFInterpreter`:

```swift
func collectOverflow(_ node: XNode, knownChildren: Set<String>) -> [String: String]?
```

Walks `node.children`, skips any whose name is in `knownChildren`, serializes the rest back to XML strings. Key is element name, value is the full XML fragment.

Example: `<applicationdata><foo>bar</foo></applicationdata>` becomes:
```swift
["applicationdata": "<applicationdata><foo>bar</foo></applicationdata>"]
```

**Three collection points** (matching the three model overflow fields):

| Model | Collects from | Known children |
|-------|--------------|----------------|
| `UDDFDocument.overflow` | `<uddf>` root | generator, gasdefinitions, diver, divesite, decomodel, profiledata |
| `UDDFDive.overflow` | `<dive>` element | informationbeforedive, informationafterdive, tankdata, samples |
| `UDDFSite.overflow` | `<site>` element | name, aliasname, environment, geography, sitedata, rating, notes |

To serialize an `XNode` subtree back to XML, add a `func toXML() -> String` method on `XNode`.

### Splicing (Export Side)

After emitting all known children of an element, emit overflow entries via `builder.rawXML()`. Overflow is already well-formed XML from a previous parse — no escaping applied.

## Testing Strategy

### Round-Trip Golden Test

Parse `minimal-valid.uddf` → export → re-parse → compare every field:
- `UDDFDocument`: version, generator, mixes, sites, diveBases, decoModels
- `UDDFDive`: all before/after fields, tanks, waypoint count
- `UDDFWaypoint`: time, depth, temperature, tankPressures, switchMixRef, diveMode, calculatedPO2, ndl
- `UDDFMix`: id, name, o2, n2, he
- `UDDFSite`: id, name, latitude, longitude

### Overflow Round-Trip Test

Synthetic UDDF with unknown elements at document/dive/site level:
1. Parse → verify overflow dictionaries populated
2. Export → re-parse → verify overflow survived
3. Verify known fields unaffected by overflow presence

### Escaping Tests

- Text with `&`, `<`, `>` survives round-trip
- Attribute values with `"`, `\r`, `\n`, `\t` survive round-trip
- Invalid XML chars (null, C0 controls) stripped
- `isValidXMLChar` boundary tests at range edges

### Export-Only Tests

- Exported XML is well-formed (re-parseable by `XMLTreeParser`)
- Generator override: custom generator appears in output
- Generator fallback: uses `document.generator` when parameter is nil
- Empty/minimal documents export without error
- Large waypoint sets export correctly

### Performance Tests

`measure` blocks for baseline metrics:

| Test | Fixture | Measures |
|------|---------|----------|
| Import small | `minimal-valid.uddf` (2.5 KB) | Parse throughput |
| Import large | `divinglog6-mk3i.uddf` (1.9 MB) | Parse throughput at scale |
| Export small | Parsed `minimal-valid.uddf` | Export throughput |
| Export large | Parsed `divinglog6-mk3i.uddf` | Export throughput at scale |
| Round-trip | Parse + export + re-parse | End-to-end cost |

## Files to Create

| File | Purpose |
|------|---------|
| `Sources/UDDF/Export/UDDFExporter.swift` | Public API |
| `Sources/UDDF/Export/UDDFDocumentWriter.swift` | Model tree walker |
| `Sources/UDDF/Export/XMLBuilder.swift` | XML rendering |
| `Sources/UDDF/Export/XMLEscaping.swift` | Escaping functions |
| `Tests/UDDFTests/Export/RoundTripTests.swift` | Golden file round-trip |
| `Tests/UDDFTests/Export/OverflowRoundTripTests.swift` | Overflow preservation |
| `Tests/UDDFTests/Export/XMLEscapingTests.swift` | Escaping correctness |
| `Tests/UDDFTests/Export/ExporterTests.swift` | Export-only tests |
| `Tests/UDDFTests/Performance/PerformanceTests.swift` | Import + export benchmarks |

## Files to Modify

| File | Change |
|------|--------|
| `Sources/UDDF/XML/XMLNode.swift` | Add `toXML() -> String` for overflow serialization |
| `Sources/UDDF/Parser/StandardUDDFInterpreter.swift` | Add `collectOverflow()`, call at document/dive/site level |
| `Sources/UDDF/Parser/ShearwaterInterpreter.swift` | Pass through overflow from standard interpreter |

## Non-Goals

- UDDF validation (checking required elements are present)
- Pretty-printing options beyond 2-space indent
- Streaming/incremental export
- UDDF 3.3 features
