# UDDF 3.2.3 Full Spec Coverage Plan

## Status: Draft

## Goal

Make the `UDDF` Swift model layer a **complete, faithful representation** of the UDDF 3.2.3 XML schema. Every element and attribute in the spec gets a corresponding Swift property with the **exact type the spec prescribes** (Double for real values, Int for integers, String for strings, enums for enumerated values). No wrappers, no unit types — just the raw UDDF values in their canonical SI units.

---

## Gap Analysis: Current vs Spec

### What We Have (Good Shape)

| Area | Status |
|------|--------|
| `UDDFDocument` root | ✅ version, generator, owner, buddies, mixes, sites, diveBases, dives |
| `UDDFGenerator` | ✅ name, type, version, datetime, manufacturer |
| `UDDFMix` | ✅ id, name, o2, n2, he, ar, h2 |
| `UDDFSite` | ✅ geography, sitedata basics, environment enum |
| `UDDFDive` before-dive | ✅ number, datetime, altitude, surfacePressure, airTemp, surfaceInterval, apparatus, platform, purpose, stateOfRest, site/buddy/equipment refs |
| `UDDFDive` after-dive | ✅ depths, duration, temp, PO2, visibility, desat, noFlight, pressureDrop, current, comfort, workload, program, rating, notes |
| `UDDFTankData` | ✅ id, mixRef, tankRef, pressures, volume, consumption |
| `UDDFWaypoint` | ✅ time, depth, temp, tankPressures[], switchMix, diveMode, PO2s, cns, ndl, decoStops[], gradientFactor, heading, heartRate, alarms[], otu, bodyTemp, battery, marker, remainingBottomTime, remainingO2Time |
| All 13 enums | ✅ complete raw values matching spec |

### Gaps to Fill

#### 1. `UDDFSex` — Missing `hermaphrodite` case
Spec defines 4 values: `undetermined | male | female | hermaphrodite`. We have 3.

#### 2. `UDDFMix` — Missing `maximumpo2` and `maximumoperationdepth`
Some generators (Shearwater, Diving Log) emit these. Spec allows them.
- `maximumPO2: Double?` — Pascals
- `maximumOperationDepth: Double?` — meters

#### 3. `UDDFPersonalInfo` — Missing fields
Spec has:
- `honorific: String?`
- `height: Double?` — meters
- `weight: Double?` — kg
- `membership` — could be array of `UDDFMembership` (org + memberid)

#### 4. `UDDFOwner` — Missing address, contact, medical, education
Spec has full address/contact blocks plus medical, education, divepermissions, diveinsurances. These are rarely populated by dive computers but exist in the spec.

**Proposal:** Add `UDDFAddress`, `UDDFContact` structs (shared by owner, buddy, divebase, maker). Add `address` and `contact` to owner/buddy. Defer medical/education/divepermissions/diveinsurances — these are desktop logbook features, not dive computer output. Document as "not yet parsed" in code.

#### 5. `UDDFBuddy` — Missing address, contact
Same shared structs as owner.

#### 6. `UDDFDiveBase` — Incomplete
Spec has: name, address, contact, guide (link ref), pricing, rating, notes, aliasname.

**Proposal:** Add address, contact, notes, rating. Defer guide/pricing as rare.

#### 7. `UDDFDiveComputer` — Missing `softwareVersion`
APD files include `<softwareversion>` on dive computers.

#### 8. `UDDFEquipmentList` — Only has `diveComputer`
Spec defines 18+ equipment types (boots, BCD, camera, compass, fins, gloves, knife, lead, light, mask, rebreather, regulator, scooter, suit, tank, variouspieces, videocamera, watch). Each has common children: name, manufacturer, model, serialnumber, purchase, serviceinterval.

**Proposal:** Add `UDDFEquipmentItem` generic struct for any equipment piece, plus specific typed items for `tank` (has `tankvolume`, `tankmaterial`) and `suit` (has `suittype`). Store as `[UDDFEquipmentItem]` on `UDDFEquipmentList`.

New enums needed:
- `UDDFEquipmentType` — boots, buoyancycontroldevice, camera, compass, compressor, divecomputer, fins, gloves, knife, lead, light, mask, rebreather, regulator, scooter, suit, tank, variouspieces, videocamera, watch
- `UDDFSuitType` — dive-skin, wet-suit, dry-suit, hot-water-suit, other
- `UDDFTankMaterial` — aluminium, carbon, steel

#### 9. `UDDFSite` — Missing rating, aliasname, wreck, ecology
Spec allows `<rating><ratingvalue>`, `<aliasname>`, `<wreck>` (complex), and `<ecology>`.

**Proposal:** Add `rating: Double?`, `aliasname: String?`. Defer wreck/ecology details (store as String? notes if present).

#### 10. `UDDFDive` — Missing fields
Before-dive:
- `noSuit: Bool?` — `<nosuit/>` empty element
- `price: Double?` — dive cost

After-dive:
- `leadQuantity: Double?` — from `<equipmentused><leadquantity>` (weight in kg)
- `observations: String?` — marine life observations (APD, Shearwater use this)

**Note:** `anysymptoms` exists in Shearwater files. Add `symptoms: String?`.

#### 11. `UDDFWaypoint` — Missing CCR/rebreather fields
The APD CCR file reveals these gaps:
- `measuredPO2s: [UDDFSensorReading]` — **multiple** measured PO2 values with sensor refs (we only have single `measuredPO2`)
- `batteryVoltages: [UDDFSensorReading]` — multiple battery readings with refs
- `scrubber: [UDDFSensorReading]` — scrubber monitor readings with refs
- `setGFHigh: Double?` — gradient factor high setting
- `setGFLow: Double?` — gradient factor low setting
- `timeToSurface: Double?` — TTS in seconds

**Proposal:** Create `UDDFSensorReading` struct (ref: String?, value: Double) — reusable for measured PO2, battery voltage, scrubber readings.

Keep `measuredPO2: Double?` as deprecated convenience (first reading). Add `measuredPO2s: [UDDFSensorReading]` as the spec-correct field.

#### 12. `UDDFAlarm` — Missing `level` and `tankref` attributes
Spec: `<alarm level="..." tankref="...">value</alarm>`

#### 13. `UDDFDocument` — Missing top-level sections
Spec defines these additional top-level children of `<uddf>`:
- `<mediadata>` — images, audio, video references
- `<maker>` — manufacturer/vendor directory
- `<decomodel>` — decompression model parameters (Buhlmann etc)
- `<divetrip>` — dive travel/vacation grouping
- `<business>` — dive shop info
- `<divecomputercontrol>` — settings for uploading to computers
- `<tablegeneration>` — decompression table generation settings

**Proposal:**
- Add `UDDFDecoModel` (id, name, GF high/low) — Shearwater files use this
- Defer mediadata, maker, business, divecomputercontrol, tablegeneration — these are desktop logbook features, not parsing targets for v0.x

#### 14. `UDDFDive` — Missing `applicationdata`
Vendor-specific passthrough data. Not parsed but should be preserved.

**Proposal:** Add `applicationData: [String: String]?` as opaque key-value pairs.

#### 15. Repetition Group structure
Currently we store `repetitionGroupId` on each dive but don't model the group itself.

**Proposal:** Fine as-is — the flattened representation with `repetitionGroupId` is more practical for consumers. Document this design decision.

---

## Implementation Plan

### Phase 1: Model Completeness (no parser changes yet)

All changes are additive — no breaking changes to existing public API.

**Step 1: New shared types**
- `UDDFAddress` — street, city, postcode, country, province
- `UDDFContact` — phone, mobilephone, fax, email, homepage, language
- `UDDFSensorReading` — ref: String?, value: Double (for multi-sensor PO2, battery, scrubber)
- `UDDFMembership` — organization: String, memberId: String

**Step 2: Enum additions**
- `UDDFSex` — add `hermaphrodite` case
- `UDDFEquipmentType` — new enum (20 cases)
- `UDDFSuitType` — new enum (5 cases)
- `UDDFTankMaterial` — new enum (3 cases)

**Step 3: Model field additions**
- `UDDFMix` — add `maximumPO2: Double?`, `maximumOperationDepth: Double?`
- `UDDFPersonalInfo` — add `honorific`, `height`, `weight`
- `UDDFOwner` — add `address: UDDFAddress?`, `contact: UDDFContact?`
- `UDDFBuddy` — add `address: UDDFAddress?`, `contact: UDDFContact?`
- `UDDFDiveComputer` — add `softwareVersion: String?`
- `UDDFDiveBase` — add `address`, `contact`, `notes`, `rating`, `aliasname`
- `UDDFSite` — add `rating: Double?`, `aliasname: String?`
- `UDDFDive` — add `noSuit`, `price`, `leadQuantity`, `observations`, `symptoms`, `applicationData`
- `UDDFWaypoint` — add `measuredPO2s`, `batteryVoltages`, `scrubberReadings` (all `[UDDFSensorReading]`), `setGFHigh`, `setGFLow`, `timeToSurface`
- `UDDFAlarm` — add `level: Double?`, `tankRef: String?`

**Step 4: Equipment model**
- `UDDFEquipmentItem` — generic equipment (type, id, name, manufacturer, model, serialNumber, purchase, notes)
- Specific fields for tank (tankVolume, tankMaterial) and suit (suitType)
- `UDDFEquipmentList` — add `items: [UDDFEquipmentItem]` alongside existing `diveComputer`

**Step 5: Deco model**
- `UDDFDecoModel` — id, name/type, gradient factor high/low
- Add `decoModels: [UDDFDecoModel]` to `UDDFDocument`

### Phase 2: Parser Updates

Update StandardUDDFInterpreter to parse all new fields. Then update Shearwater/Subsurface interpreters for their quirks.

**Step 6: Standard interpreter — new field parsing**
- Parse address/contact blocks (shared helper)
- Parse equipment items from `<equipment>`
- Parse deco model from `<decomodel>`
- Parse new site fields (rating, aliasname)
- Parse new dive fields (noSuit, price, leadQuantity, observations, symptoms)
- Parse new waypoint fields (measuredPO2s, batteryVoltages, scrubberReadings, setGFHigh, setGFLow, timeToSurface)
- Parse alarm attributes (level, tankref)
- Parse mix maximumpo2 / maximumoperationdepth

**Step 7: Shearwater interpreter updates**
- Handle maximumpo2 on mixes
- Handle observations/symptoms from notes
- Handle deco model references

**Step 8: APD interpreter**
New interpreter for AP DiveSight files (already have test fixture):
- Multiple measured PO2 sensors
- Battery voltage arrays
- Scrubber monitor readings
- SetGF high/low per waypoint
- Equipment: rebreather, O2 sensors, batteries

### Phase 3: Test Coverage

**Step 9: Model-level tests**
- Codable round-trip tests for all new types
- Enum raw value tests (every case matches spec string)
- `UDDFSensorReading` array handling

**Step 10: Parser tests for new fields**
- Update minimal-valid.uddf fixture to include new elements
- APD fixture tests for CCR-specific fields
- Diving Log fixture tests for maximumoperationdepth, heading, heartrate
- Subsurface fixture tests for buddy, equipment, rating

**Step 11: Spec conformance test suite**
- One test per UDDF element that asserts: "if present in XML, it appears in parsed model"
- Ensure no data is silently dropped

---

## Design Decisions

1. **Flat doubles, not typed wrappers** — `visibility: Double?` (meters), not `Measurement<UnitLength>`. The library is a parser, not a UI framework. Consumers bring their own unit display.

2. **Optional everything** — UDDF is wildly inconsistent across generators. Almost nothing is truly required in practice. Default to `nil`.

3. **Arrays for multi-value fields** — `measuredPO2s: [UDDFSensorReading]`, not single values. The spec says these can repeat.

4. **Deprecated wrappers preserved** — `measuredPO2: Double?` stays as deprecated convenience pointing to first element of `measuredPO2s`. No breaking changes.

5. **Flattened dives** — Keep `repetitionGroupId` on dive rather than nesting. More practical for consumers.

6. **Deferred sections** — `mediadata`, `maker`, `business`, `tablegeneration`, `divecomputercontrol`, `medical`, `education`, `divepermissions`, `diveinsurances` are documented as "not yet parsed" — extremely rare in real-world files.

---

## Files to Create/Modify

### New Files
- `Sources/UDDF/Model/UDDFAddress.swift` — Address + Contact
- `Sources/UDDF/Model/UDDFSensorReading.swift` — Multi-sensor reading
- `Sources/UDDF/Model/UDDFEquipmentItem.swift` — Full equipment model
- `Sources/UDDF/Model/UDDFDecoModel.swift` — Decompression model
- `Sources/UDDF/Parser/APDInterpreter.swift` — AP DiveSight interpreter
- `Tests/UDDFTests/ModelCodableTests.swift` — Codable round-trips
- `Tests/UDDFTests/SpecConformanceTests.swift` — Every element has a test

### Modified Files
- `Sources/UDDF/Model/UDDFEnums.swift` — new enums + hermaphrodite
- `Sources/UDDF/Model/UDDFMix.swift` — maxPO2, maxOD
- `Sources/UDDF/Model/UDDFDiver.swift` — address, contact, personal fields
- `Sources/UDDF/Model/UDDFDive.swift` — new before/after fields
- `Sources/UDDF/Model/UDDFWaypoint.swift` — sensor arrays, GF settings, TTS
- `Sources/UDDF/Model/UDDFWaypointTypes.swift` — alarm level/tankref
- `Sources/UDDF/Model/UDDFSite.swift` — rating, aliasname
- `Sources/UDDF/Model/UDDFDocument.swift` — decoModels, diveComputer softwareVersion
- `Sources/UDDF/Parser/StandardUDDFInterpreter.swift` — parse all new fields
- `Sources/UDDF/Parser/ShearwaterInterpreter.swift` — new field handling
- `Sources/UDDF/Parser/UDDFInterpreting.swift` — register APD interpreter
