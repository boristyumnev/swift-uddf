# swift-uddf

A Swift library for parsing [UDDF](https://uddf.org) (Universal Dive Data Format) files — the standard XML format used by dive computers and dive log software.

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%2014%20|%20iOS%2017-blue.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- UDDF 3.2.3 model — every spec element and attribute has a typed Swift property
- Auto-detects dive computer software and handles generator-specific quirks
- Full waypoint telemetry: depth, temperature, multiple tank pressures, PO2 (calculated, measured, setpoint), CNS, NDL, deco stops, gradient factors, heading, heart rate, alarms, OTU, battery, scrubber
- CCR/rebreather support: multiple O2 sensors, battery voltages, scrubber readings, GF high/low per waypoint
- Gas mix definitions with all fractions (O2, N2, He, Ar, H2) plus maximum PO2/MOD
- Equipment inventory: 20 equipment types with manufacturer, model, serial, suit type, tank material
- Diagnostics system reports parsing issues without failing
- Zero dependencies — Foundation only
- Swift 6 strict concurrency (`Sendable` throughout)
- 157 tests against real dive files from Shearwater, Subsurface, APD Inspiration, Diving Log 6.0

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

// Basic dive info
for dive in doc.dives {
    print("#\(dive.number ?? 0) — \(dive.datetime ?? "?")")
    print("  Depth: \(dive.greatestDepth ?? 0) m, Duration: \((dive.duration ?? 0) / 60) min")
}

// Check for parsing issues
for diag in result.diagnostics where diag.level == .warning {
    print("[\(diag.level)] \(diag.message)")
}
```

## Usage Patterns

### Access dive metadata

```swift
let dive = doc.dives[0]

// Before-dive info
dive.datetime                  // "2024-07-29T17:44:18Z"
dive.number                    // 31
dive.surfacePressure           // 101325.0 (Pascals)
dive.airTemperature            // 297.15 (Kelvin)
dive.surfaceInterval           // 3600.0 (seconds)
dive.surfaceIntervalIsInfinity // true = first dive of series
dive.apparatus                 // .openScuba
dive.platform                  // .charterBoat
dive.purpose                   // .sightseeing

// After-dive info
dive.greatestDepth             // 30.5 (meters)
dive.duration                  // 2400.0 (seconds)
dive.visibility                // 15.0 (meters)
dive.current                   // .moderate
dive.thermalComfort            // .comfortable
dive.rating                    // 8.0
dive.notes                     // "Great dive..."
```

### Resolve cross-references

UDDF uses string IDs to cross-reference mixes, sites, and buddies.

```swift
// Site for a dive
if let siteRef = dive.siteRef, let site = doc.sites[siteRef] {
    print("Site: \(site.name ?? "?") at \(site.latitude ?? 0), \(site.longitude ?? 0)")
    print("Environment: \(site.environment ?? .unknown)")
}

// Gas mixes used
for tank in dive.tanks {
    if let mixRef = tank.mixRef, let mix = doc.mixes[mixRef] {
        print("Gas: \(mix.name ?? "?") — O2: \(mix.o2), He: \(mix.he)")
    }
    let barBegin = (tank.pressureBegin ?? 0) / 100_000
    let barEnd = (tank.pressureEnd ?? 0) / 100_000
    print("  \(barBegin) → \(barEnd) bar")
}

// Buddies
for buddyRef in dive.buddyRefs {
    if let buddy = doc.buddies.first(where: { $0.id == buddyRef }) {
        print("Buddy: \(buddy.personal?.firstName ?? buddy.id)")
    }
}
```

### Walk waypoint profile

```swift
for wp in dive.waypoints {
    let minutes = wp.time / 60
    let celsius = wp.temperature.map { $0 - 273.15 }

    print("\(minutes) min — \(wp.depth) m, \(celsius ?? 0)°C")

    // Gas switches
    if let mixRef = wp.switchMixRef {
        print("  ⛽ Switch to \(mixRef)")
    }

    // Multiple tank pressures (multi-tank setups)
    for tp in wp.tankPressures {
        let bar = tp.value / 100_000
        print("  Tank \(tp.ref ?? "?"): \(bar) bar")
    }

    // Decompression
    if let ndl = wp.ndl {
        print("  NDL: \(ndl / 60) min")
    }
    for stop in wp.decoStops {
        print("  Deco: \(stop.kind ?? .safety) at \(stop.depth ?? 0) m for \(stop.duration ?? 0) s")
    }
}
```

### CCR / rebreather data

```swift
for wp in dive.waypoints {
    // Multiple O2 sensors
    for sensor in wp.measuredPO2s {
        let bar = sensor.value / 100_000
        print("  Sensor \(sensor.ref ?? "?"): \(bar) bar PO2")
    }

    // PO2 setpoint
    if let setPO2 = wp.setPO2 {
        let bar = setPO2 / 100_000
        print("  Setpoint: \(bar) bar (set by \(wp.setPO2SetBy ?? .computer))")
    }

    // Battery voltages
    for batt in wp.batteryVoltages {
        print("  Battery \(batt.ref ?? "?"): \(batt.value) V")
    }

    // Scrubber readings
    for scrub in wp.scrubberReadings {
        print("  Scrubber \(scrub.ref ?? "?"): \(scrub.value)")
    }

    // Gradient factor settings per waypoint
    if let gfHigh = wp.setGFHigh {
        print("  GF: \(wp.setGFLow ?? 0)/\(gfHigh)")
    }
}
```

### Equipment inventory

```swift
if let equipment = doc.owner?.equipment {
    for item in equipment.items {
        print("\(item.type): \(item.name ?? "?") — \(item.manufacturer ?? "")")
        if let serial = item.serialNumber { print("  S/N: \(serial)") }
        if let vol = item.tankVolume { print("  Volume: \(vol * 1000) L") }
        if let suit = item.suitType { print("  Suit: \(suit)") }
    }

    // Convenience accessor
    if let dc = equipment.diveComputer {
        print("Dive computer: \(dc.model ?? "?") S/N \(dc.serialNumber ?? "?")")
    }
}
```

### Convert to display units

All values use UDDF canonical SI units — convert in your app layer:

```swift
let celsius = waypoint.temperature! - 273.15
let bar = tank.pressureBegin! / 100_000
let liters = tank.volume! * 1000
let feet = dive.greatestDepth! * 3.28084
let minutes = dive.duration! / 60
```

## Architecture

Two-layer pipeline:

1. **Layer 1 — XML Parsing**: SAX parser builds a generic `XNode` tree. No UDDF knowledge.
2. **Layer 2 — Interpretation**: Generator-aware interpreters extract typed `UDDFDocument` from the tree.

### Generator Support

| Generator | Status | Quirks Handled |
|-----------|--------|----------------|
| Standard UDDF 3.2 | Full | Baseline spec compliance |
| Shearwater Cloud | Full | Compound mix IDs, pressure sentinels, freeform visibility, dive mode inference from mix prefix |
| Subsurface | Delegates to standard | — |
| Diving Log 6.0 | Delegates to standard | — |
| AP DiveSight | Delegates to standard | — |

To add support for a new generator, implement `UDDFInterpreting` and register in `InterpreterFactory`.

## UDDF 3.2.3 Spec Coverage

### Fully Parsed

| Section | Element | Swift Type | Fields |
|---------|---------|------------|--------|
| Root | `<uddf>` | `UDDFDocument` | version, generator, owner, buddies, mixes, sites, diveBases, decoModels, dives |
| Generator | `<generator>` | `UDDFGenerator` | name, type, version, datetime, manufacturer |
| Dive computer | `<divecomputer>` | `UDDFDiveComputer` | name, model, serialNumber, softwareVersion |
| Gas definitions | `<mix>` | `UDDFMix` | id, name, o2, n2, he, ar, h2, maximumPO2, maximumOperationDepth |
| Diver | `<owner>` | `UDDFOwner` | personal, address, contact, equipment |
| Diver | `<buddy>` | `UDDFBuddy` | id, personal, address, contact |
| Personal info | `<personal>` | `UDDFPersonalInfo` | firstName, middleName, lastName, honorific, sex, birthdate, height, weight, memberships |
| Address | `<address>` | `UDDFAddress` | street, city, postcode, country, province |
| Contact | `<contact>` | `UDDFContact` | phone, mobilephone, fax, email, homepage, language |
| Equipment | 20 types | `UDDFEquipmentItem` | type, id, name, manufacturer, model, serialNumber, softwareVersion, tankVolume, tankMaterial, suitType |
| Dive site | `<site>` | `UDDFSite` | id, name, aliasname, environment, location, lat/lon, altitude, country, province, min/max depth, density, bottom, rating, notes |
| Dive base | `<divebase>` | `UDDFDiveBase` | id, name, address, contact, aliasname, rating, notes |
| Deco model | `<decomodel>` | `UDDFDecoModel` | id, name, gradientFactorHigh, gradientFactorLow |
| Before-dive | `<informationbeforedive>` | on `UDDFDive` | number, divenumberOfDay, internalDiveNumber, datetime, altitude, surfacePressure, airTemperature, surfaceInterval, surfaceIntervalIsInfinity, apparatus, platform, purpose, stateOfRest, noSuit, price, siteRef, buddyRefs, equipmentRefs, decoModelRef |
| After-dive | `<informationafterdive>` | on `UDDFDive` | greatestDepth, averageDepth, duration, lowestTemperature, highestPO2, visibility, desaturationTime, noFlightTime, pressureDrop, current, thermalComfort, workload, program, rating, equipmentUsedRefs, leadQuantity, surfaceIntervalAfterDive, observations, symptoms, notes |
| Tank data | `<tankdata>` | `UDDFTankData` | id, mixRef, tankRef, pressureBegin, pressureEnd, volume, breathingConsumptionVolume |
| Waypoint | `<waypoint>` | `UDDFWaypoint` | time, depth, temperature, tankPressures, switchMixRef, diveMode, calculatedPO2, measuredPO2s, setPO2, setPO2SetBy, cns, ndl, decoStops, gradientFactor, setGFHigh, setGFLow, timeToSurface, heading, heartRate, alarms, otu, bodyTemperature, batteryChargeCondition, batteryVoltages, scrubberReadings, setMarker, remainingBottomTime, remainingO2Time |
| Supporting | `<tankpressure>` | `UDDFTankPressure` | ref, value |
| Supporting | `<alarm>` | `UDDFAlarm` | type, message, level, tankRef |
| Supporting | `<decostop>` | `UDDFDecoStop` | kind, depth, duration |
| Supporting | Sensor readings | `UDDFSensorReading` | ref, value |
| Repetition group | `<repetitiongroup>` | `repetitionGroupId` on dive | Flattened — group ID stored per dive |

### Enums (20 total, all `String, Codable, Sendable`)

| Enum | Cases |
|------|-------|
| `UDDFDiveMode` | apnea, opencircuit, closedcircuit, semiclosedcircuit |
| `UDDFApparatus` | open-scuba, rebreather, surface-supplied, chamber, experimental, other |
| `UDDFPlatform` | beach-shore, pier, small-boat, charter-boat, live-aboard, barge, landside, hyperbaric-facility, other |
| `UDDFPurpose` | sightseeing, learning, teaching, research, photography-videography, spearfishing, proficiency, work, other |
| `UDDFCurrent` | no-current, very-mild-current, mild-current, moderate-current, hard-current, very-hard-current |
| `UDDFThermalComfort` | not-indicated, comfortable, cold, very-cold, hot |
| `UDDFWorkload` | not-specified, resting, light, moderate, severe, exhausting |
| `UDDFProgram` | recreation, training, scientific, medical, commercial, military, competitive, other |
| `UDDFStateOfRest` | not-specified, rested, tired, exhausted |
| `UDDFEnvironment` | unknown, ocean-sea, lake-quarry, river-spring, cave-cavern, pool, hyperbaric-chamber, under-ice, other |
| `UDDFDecoStopKind` | safety, mandatory |
| `UDDFSetBySource` | user, computer |
| `UDDFAlarmType` | ascent, breath, deco, error, link, microbubbles, rbt, skincooling, surface |
| `UDDFSex` | undetermined, male, female, hermaphrodite |
| `UDDFEquipmentType` | boots, buoyancycontroldevice, camera, compass, compressor, divecomputer, equipmentconfiguration, fins, gloves, knife, lead, light, mask, rebreather, regulator, scooter, suit, tank, variouspieces, videocamera, watch |
| `UDDFSuitType` | dive-skin, wet-suit, dry-suit, hot-water-suit, other |
| `UDDFTankMaterial` | aluminium, carbon, steel |
| `DiagnosticLevel` | info, warning, error |

### Not Yet Parsed

These UDDF sections are defined in the spec but not commonly emitted by dive computers. They are documented here for completeness.

| Section | Reason Deferred |
|---------|----------------|
| `<mediadata>` (images, audio, video) | Desktop logbook feature — file references, not dive data |
| `<maker>` (manufacturer directory) | Vendor catalog, not dive-relevant |
| `<business>` (dive shop info) | Operator data, structurally similar to divebase |
| `<divetrip>` (vacation grouping) | Organizational, not profile data |
| `<divecomputercontrol>` (upload settings) | Computer configuration, not parsing |
| `<tablegeneration>` (deco table settings) | Table generation parameters |
| `<medical>`, `<education>`, `<divepermissions>`, `<diveinsurances>` | Diver record details, rarely populated |
| `<ecology>`, `<wreck>` (site details) | Rich site metadata, rare in exports |
| `<applicationdata>` (vendor-specific) | Opaque passthrough data |
| `<plannedprofile>` (intended dive plan) | Pre-dive planning data |

### Units Reference

All values use UDDF canonical SI units:

| Dimension | Unit | Example |
|-----------|------|---------|
| Depth | meters | `30.5` |
| Temperature | Kelvin | `288.15` (= 15°C) |
| Pressure | Pascals | `20000000` (= 200 bar) |
| Volume | cubic meters | `0.012` (= 12 L) |
| Time | seconds | `2400` (= 40 min) |
| Density | kg/m³ | `1025` (saltwater) |
| Gas fraction | 0.0–1.0 | `0.32` (= 32% O2) |
| Latitude | decimal degrees | `47.5` (north +, south −) |
| Longitude | decimal degrees | `-122.3` (east +, west −) |
| Altitude | meters | `0` (sea level) |
| Height/Weight | meters / kg | `1.80` / `75.0` |

## License

MIT — see [LICENSE](LICENSE).
