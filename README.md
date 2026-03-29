# swift-uddf

A Swift library for parsing [UDDF](https://uddf.org) (Universal Dive Data Format) files — the standard XML format used by dive computers and dive log software.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%2014%20|%20iOS%2017-blue.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- Parse UDDF 3.2.x files into typed Swift structures
- Auto-detects dive computer software (Shearwater, Subsurface) and handles generator-specific quirks
- Full waypoint telemetry: depth, temperature, tank pressure, PO2, CNS, NDL, ceiling, heading, heart rate
- Gas mix definitions, dive sites, tank data
- Diagnostics system reports parsing issues without failing
- Zero dependencies — Foundation only
- Swift 6 strict concurrency (`Sendable` throughout)
- Tested against real dive files from Shearwater Perdix 2, Subsurface, APD Inspiration, Diving Log 6.0

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/boristyumnev/swift-uddf.git", from: "0.1.0")
```

Then add `"UDDF"` to your target's dependencies:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "UDDF", package: "swift-uddf")
])
```

### Xcode

File > Add Package Dependencies > paste the repository URL.

## Quick Start

```swift
import UDDF

let data = try Data(contentsOf: uddfFileURL)
let result = try UDDFParser.parse(data: data)

let doc = result.document
print("Generator: \(doc.generator.name)")
print("Dives: \(doc.dives.count)")

for dive in doc.dives {
    print("  #\(dive.number ?? 0) — \(dive.datetime ?? "?")")
    print("  Max depth: \(dive.greatestDepth ?? 0) m")
    print("  Duration: \(dive.duration ?? 0) s")
    print("  Waypoints: \(dive.waypoints.count)")
}

// Check for parsing issues
for diag in result.diagnostics {
    print("[\(diag.level)] \(diag.message)")
}
```

## Architecture

Two-layer pipeline:

1. **Layer 1 — XML Parsing**: SAX parser builds a generic `XNode` tree. No UDDF knowledge.
2. **Layer 2 — Interpretation**: Generator-aware interpreters extract typed `UDDFDocument` from the tree.

### Generator Support

| Generator | Status | Quirks Handled |
|-----------|--------|----------------|
| Standard UDDF 3.2 | Full | Baseline spec compliance |
| Shearwater Cloud | Full | Compound mix IDs, pressure sentinels, freeform visibility, dive mode inference |
| Subsurface | Basic | Delegates to standard |

### Units

All values use UDDF canonical units:

| Dimension | Unit |
|-----------|------|
| Depth | meters |
| Temperature | Kelvin |
| Pressure | Pascals |
| Volume | cubic meters (m3) |
| Time | seconds |

Convert to display units in your app layer:

```swift
let celsius = waypoint.temperature! - 273.15
let bar = dive.tanks[0].pressureBegin! / 100_000
let liters = dive.tanks[0].volume! * 1000
```

## Key Types

| Type | Description |
|------|-------------|
| `UDDFParser` | Single entry point — call `parse(data:)` |
| `ParseResult` | Document + diagnostics |
| `UDDFDocument` | Top-level container (version, generator, mixes, sites, dives) |
| `UDDFDive` | Dive metadata + waypoints + tank data |
| `UDDFWaypoint` | Single time-series sample with full telemetry |
| `UDDFMix` | Gas mix definition (O2, He, Ar, H2 fractions) |
| `UDDFSite` | Dive site with name, coordinates, geography |
| `UDDFTankData` | Tank pressures and volume per gas |
| `ParseDiagnostic` | Info/warning/error messages from parsing |

## Adding Generator Support

Implement `UDDFInterpreting` and register in `InterpreterFactory`:

```swift
public struct MyDiveComputerInterpreter: UDDFInterpreting {
    public func interpret(tree: XNode) throws -> ParseResult {
        // Override specific parsing for your generator's quirks
        // Delegate to StandardUDDFInterpreter for baseline behavior
    }
}
```

## License

MIT — see [LICENSE](LICENSE).
