import Foundation

/// Interprets Shearwater UDDF exports with generator-specific overrides.
///
/// Shearwater quirks handled:
/// - Mix ID format: `"OC1:32/00"` or `"CC1:21/00"` (prefix encodes slot + mode)
/// - Dive mode inference from mix ref prefix (OC → open circuit, CC → closed circuit)
/// - Tank pressure sentinel value `56247452` → treat as nil
/// - Visibility as freeform string (`"50 ft"`) instead of numeric
/// - Metadata embedded in notes (`-ShearwaterDiveModeType:6-`)
/// - Site ref resolution from multiple `<link>` elements
/// - Buddy name stuffed into `<firstname>` (full name, no `<lastname>`)
/// - `maximumpo2` on mixes
public struct ShearwaterInterpreter: UDDFInterpreting, Sendable {

    /// Shearwater's sentinel value for "no tank pressure data"
    static let pressureSentinel: Double = 56247452

    private let standard = StandardUDDFInterpreter()

    public init() {}

    public func interpret(tree: XNode) throws -> ParseResult {
        var diagnostics: [ParseDiagnostic] = []

        let version = tree.attribute("version") ?? "unknown"
        let generator = standard.parseGenerator(tree, diagnostics: &diagnostics)
        let (owner, buddies) = standard.parseDiver(tree, diagnostics: &diagnostics)
        let mixes = parseMixes(tree, diagnostics: &diagnostics)
        let (sites, diveBases) = standard.parseSites(tree, diagnostics: &diagnostics)
        let decoModels = standard.parseDecoModels(tree)
        let dives = parseDives(tree, knownSiteIds: Set(sites.keys), mixes: mixes, diagnostics: &diagnostics)

        diagnostics.insert(
            ParseDiagnostic(
                level: .info,
                message: "Detected Shearwater: \(generator.name) v\(generator.version ?? "?")",
                context: "generator"
            ),
            at: 0
        )

        let document = UDDFDocument(
            version: version,
            generator: generator,
            owner: owner,
            buddies: buddies,
            mixes: mixes,
            sites: sites,
            diveBases: diveBases,
            decoModels: decoModels,
            dives: dives
        )

        return ParseResult(document: document, diagnostics: diagnostics)
    }

    // MARK: - Mixes

    func parseMixes(_ tree: XNode, diagnostics: inout [ParseDiagnostic]) -> [String: UDDFMix] {
        var mixes: [String: UDDFMix] = [:]

        let mixNodes = tree.query("gasdefinitions", "mix")
        for node in mixNodes {
            guard let id = node.attribute("id") else { continue }

            let (o2, he) = extractGasFromId(id)
                ?? (node.doubleValue("o2") ?? 0.21, node.doubleValue("he") ?? 0.0)

            let mix = UDDFMix(
                id: id,
                name: node.stringValue("name"),
                o2: o2,
                n2: node.doubleValue("n2"),
                he: he,
                ar: node.doubleValue("ar"),
                h2: node.doubleValue("h2"),
                maximumPO2: node.doubleValue("maximumpo2"),
                maximumOperationDepth: node.doubleValue("maximumoperationdepth")
            )
            mixes[id] = mix
        }

        return mixes
    }

    /// Extract O2/He fractions from Shearwater's compound mix ID.
    func extractGasFromId(_ id: String) -> (o2: Double, he: Double)? {
        guard let colonIdx = id.firstIndex(of: ":") else { return nil }
        let gasPart = id[id.index(after: colonIdx)...]
        let components = gasPart.split(separator: "/")
        guard components.count == 2,
              let o2Int = Int(components[0]),
              let heInt = Int(components[1]) else { return nil }
        return (Double(o2Int) / 100.0, Double(heInt) / 100.0)
    }

    /// Infer dive mode from Shearwater mix ref prefix.
    func inferDiveMode(from mixRef: String?) -> UDDFDiveMode? {
        guard let ref = mixRef else { return nil }
        if ref.range(of: #"^OC\d+:"#, options: .regularExpression) != nil {
            return .opencircuit
        } else if ref.range(of: #"^CC\d+:"#, options: .regularExpression) != nil {
            return .closedcircuit
        }
        return nil
    }

    // MARK: - Dives

    func parseDives(_ tree: XNode, knownSiteIds: Set<String>, mixes: [String: UDDFMix], diagnostics: inout [ParseDiagnostic]) -> [UDDFDive] {
        var dives: [UDDFDive] = []

        let repGroups = tree.query("profiledata", "repetitiongroup")
        for group in repGroups {
            let groupId = group.attribute("id")
            for diveNode in group.children("dive") {
                let dive = parseSingleDive(diveNode, repetitionGroupId: groupId, knownSiteIds: knownSiteIds, mixes: mixes, diagnostics: &diagnostics)
                dives.append(dive)
            }
        }

        return dives
    }

    func parseSingleDive(_ node: XNode, repetitionGroupId: String?, knownSiteIds: Set<String>, mixes: [String: UDDFMix], diagnostics: inout [ParseDiagnostic]) -> UDDFDive {
        let before = node.child("informationbeforedive")
        let after = node.child("informationafterdive")

        let siteRef = findSiteRef(before, knownSiteIds: knownSiteIds)
        let tanks = parseTankData(node)
        let waypoints = parseWaypoints(node.child("samples"), diagnostics: &diagnostics)
        let visibility = parseVisibility(after, diagnostics: &diagnostics)
        let notes = parseNotes(after)

        // Before-dive fields
        let surfaceIntervalNode = before?.child("surfaceintervalbeforedive")
        let isInfinity = surfaceIntervalNode?.child("infinity") != nil ? true : nil
        let surfaceInterval = surfaceIntervalNode?.doubleValue("passedtime")

        // Link refs
        let allBeforeRefs = standard.extractLinkRefs(before)
        let equipUsed = after?.child("equipmentused")
        let equipmentUsedRefs = standard.extractLinkRefs(equipUsed)
        let leadQuantity = equipUsed?.doubleValue("leadquantity")

        // Rating
        let rating = after?.child("rating")?.doubleValue("ratingvalue")

        // Observations from Shearwater's <observations><notes>
        let observations = parseShearwaterObservations(after)

        // Symptoms
        let symptomsNode = after?.child("anysymptoms")
        let symptoms: String?
        if let symptomsNode {
            let paras = symptomsNode.child("notes")?.children("para").compactMap { $0.textValue } ?? []
            let joined = paras.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            symptoms = joined.isEmpty ? nil : joined
        } else {
            symptoms = nil
        }

        return UDDFDive(
            id: node.attribute("id"),
            repetitionGroupId: repetitionGroupId,
            number: before?.child("divenumber")?.textValue.flatMap { Int($0) },
            divenumberOfDay: before?.child("divenumberofday")?.textValue.flatMap { Int($0) },
            internalDiveNumber: before?.child("internaldivenumber")?.textValue.flatMap { Int($0) },
            datetime: before?.stringValue("datetime"),
            altitude: before?.doubleValue("altitude"),
            surfacePressure: before?.doubleValue("surfacepressure"),
            airTemperature: before?.doubleValue("airtemperature"),
            surfaceInterval: surfaceInterval,
            surfaceIntervalIsInfinity: isInfinity,
            apparatus: before?.stringValue("apparatus").flatMap { UDDFApparatus(rawValue: $0) },
            platform: before?.stringValue("platform").flatMap { UDDFPlatform(rawValue: $0) },
            purpose: before?.stringValue("purpose").flatMap { UDDFPurpose(rawValue: $0) },
            stateOfRest: before?.stringValue("stateofrestbeforedive").flatMap { UDDFStateOfRest(rawValue: $0) },
            siteRef: siteRef,
            buddyRefs: allBeforeRefs,
            greatestDepth: after?.doubleValue("greatestdepth"),
            averageDepth: after?.doubleValue("averagedepth"),
            duration: after?.doubleValue("diveduration"),
            lowestTemperature: after?.doubleValue("lowesttemperature"),
            highestPO2: after?.doubleValue("highestpo2"),
            visibility: visibility,
            desaturationTime: after?.doubleValue("desaturationtime"),
            noFlightTime: after?.doubleValue("noflighttime"),
            pressureDrop: after?.doubleValue("pressuredrop"),
            current: after?.stringValue("current").flatMap { UDDFCurrent(rawValue: $0) },
            thermalComfort: after?.stringValue("thermalcomfort").flatMap { UDDFThermalComfort(rawValue: $0) },
            workload: after?.stringValue("workload").flatMap { UDDFWorkload(rawValue: $0) },
            program: after?.stringValue("program").flatMap { UDDFProgram(rawValue: $0) },
            rating: rating,
            equipmentUsedRefs: equipmentUsedRefs,
            leadQuantity: leadQuantity,
            observations: observations,
            symptoms: symptoms,
            notes: notes,
            tanks: tanks,
            waypoints: waypoints
        )
    }

    // MARK: - Site Ref

    func findSiteRef(_ before: XNode?, knownSiteIds: Set<String>) -> String? {
        guard let before else { return nil }
        let links = before.children("link")
        for link in links {
            if let ref = link.attribute("ref"), knownSiteIds.contains(ref) {
                return ref
            }
        }
        return nil
    }

    // MARK: - Tank Data

    func parseTankData(_ diveNode: XNode) -> [UDDFTankData] {
        var tanks: [UDDFTankData] = []

        let tankNodes = diveNode.children("tankdata")
        for node in tankNodes {
            let mixRef = node.children("link").first?.attribute("ref")
            let beginRaw = node.doubleValue("tankpressurebegin")
            let endRaw = node.doubleValue("tankpressureend")

            let tank = UDDFTankData(
                id: node.attribute("id"),
                mixRef: mixRef,
                pressureBegin: cleanPressure(beginRaw),
                pressureEnd: cleanPressure(endRaw),
                volume: node.doubleValue("tankvolume"),
                breathingConsumptionVolume: node.doubleValue("breathingconsumptionvolume")
            )
            tanks.append(tank)
        }

        return tanks
    }

    // MARK: - Waypoints

    func parseWaypoints(_ samples: XNode?, diagnostics: inout [ParseDiagnostic]) -> [UDDFWaypoint] {
        guard let samples else { return [] }
        var waypoints: [UDDFWaypoint] = []
        var currentMode: UDDFDiveMode?

        for wp in samples.children("waypoint") {
            let tankPressures = parseTankPressures(wp)
            let switchMixRef = wp.child("switchmix")?.attribute("ref")

            let explicitMode = wp.child("divemode")?.attribute("type").flatMap { UDDFDiveMode(rawValue: $0) }
            let inferredMode = switchMixRef.flatMap { inferDiveMode(from: $0) }
            let diveMode = explicitMode ?? inferredMode ?? currentMode

            if let switchMixRef, let newMode = inferDiveMode(from: switchMixRef) {
                if let prevMode = currentMode, prevMode != newMode {
                    diagnostics.append(ParseDiagnostic(
                        level: .info,
                        message: "Mode switch detected: \(prevMode.rawValue) → \(newMode.rawValue) via mix \(switchMixRef)",
                        context: "waypoint \(wp.doubleValue("divetime") ?? 0)s"
                    ))
                }
                currentMode = newMode
            } else if let explicitMode {
                currentMode = explicitMode
            }

            let measuredPO2s = standard.parseSensorReadings(wp, elementName: "measuredpo2")
            let batteryVoltages = standard.parseSensorReadings(wp, elementName: "batteryvoltage")
            let scrubberReadings = standard.parseSensorReadings(wp, elementName: "scrubber")
            let decoStops = standard.parseDecoStops(wp, diagnostics: &diagnostics)

            let waypoint = UDDFWaypoint(
                time: wp.doubleValue("divetime") ?? 0,
                depth: wp.doubleValue("depth") ?? 0,
                temperature: wp.doubleValue("temperature"),
                tankPressures: tankPressures,
                switchMixRef: switchMixRef,
                diveMode: diveMode,
                calculatedPO2: wp.doubleValue("calculatedpo2"),
                measuredPO2s: measuredPO2s,
                setPO2: wp.child("setpo2")?.textValue.flatMap { Double($0) },
                setPO2SetBy: wp.child("setpo2")?.attribute("setby").flatMap { UDDFSetBySource(rawValue: $0) },
                cns: wp.doubleValue("cns"),
                ndl: wp.doubleValue("nodecotime"),
                decoStops: decoStops,
                gradientFactor: wp.doubleValue("gradientfactor"),
                setGFHigh: wp.doubleValue("setgfhigh"),
                setGFLow: wp.doubleValue("setgflow"),
                timeToSurface: wp.doubleValue("timetosurface"),
                heading: wp.doubleValue("heading"),
                heartRate: wp.doubleValue("heartrate") ?? wp.doubleValue("pulserate"),
                otu: wp.doubleValue("otu"),
                bodyTemperature: wp.doubleValue("bodytemperature"),
                batteryChargeCondition: wp.doubleValue("batterychargecondition"),
                batteryVoltages: batteryVoltages,
                scrubberReadings: scrubberReadings,
                setMarker: wp.child("setmarker") != nil ? true : nil,
                remainingBottomTime: wp.doubleValue("remainingbottomtime"),
                remainingO2Time: wp.doubleValue("remainingo2time")
            )
            waypoints.append(waypoint)
        }

        return waypoints
    }

    /// Parse tank pressures, stripping sentinel values.
    func parseTankPressures(_ wp: XNode) -> [UDDFTankPressure] {
        let tpNodes = wp.children("tankpressure")
        var pressures: [UDDFTankPressure] = []
        for tp in tpNodes {
            if let text = tp.textValue, let value = Double(text) {
                if let cleaned = cleanPressure(value) {
                    pressures.append(UDDFTankPressure(ref: tp.attribute("ref"), value: cleaned))
                }
            }
        }
        return pressures
    }

    // MARK: - Pressure Sentinel

    func cleanPressure(_ value: Double?) -> Double? {
        guard let v = value else { return nil }
        if v == Self.pressureSentinel { return nil }
        return v
    }

    // MARK: - Visibility

    func parseVisibility(_ after: XNode?, diagnostics: inout [ParseDiagnostic]) -> Double? {
        guard let text = after?.stringValue("visibility") else { return nil }

        if let value = Double(text) {
            return value
        }

        let pattern = #"(\d+\.?\d*)\s*(ft|feet|m|meters)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let numberRange = Range(match.range(at: 1), in: text) else {
            diagnostics.append(ParseDiagnostic(
                level: .warning,
                message: "Could not parse visibility: \"\(text)\"",
                context: "informationafterdive/visibility"
            ))
            return nil
        }

        guard let number = Double(text[numberRange]) else { return nil }

        if match.range(at: 2).location != NSNotFound,
           let unitRange = Range(match.range(at: 2), in: text) {
            let unit = text[unitRange].lowercased()
            if unit == "ft" || unit == "feet" {
                return number * 0.3048
            }
        }

        return number
    }

    // MARK: - Notes

    func parseNotes(_ after: XNode?) -> String? {
        guard let notes = after?.child("notes") else { return nil }
        let paras = notes.children("para").compactMap { $0.textValue }
        let userNotes = paras.filter { !$0.hasPrefix("-Shearwater") }
        let joined = userNotes.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }

    // MARK: - Observations

    func parseShearwaterObservations(_ after: XNode?) -> String? {
        guard let obs = after?.child("observations") else { return nil }
        let paras = obs.child("notes")?.children("para").compactMap { $0.textValue } ?? []
        // Filter out Shearwater internal metadata
        let user = paras.filter { !$0.hasPrefix("-Shearwater") }
        let joined = user.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }
}
