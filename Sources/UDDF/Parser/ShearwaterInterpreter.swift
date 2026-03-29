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
public struct ShearwaterInterpreter: UDDFInterpreting, Sendable {

    /// Shearwater's sentinel value for "no tank pressure data"
    static let pressureSentinel: Double = 56247452

    public init() {}

    public func interpret(tree: XNode) throws -> ParseResult {
        var diagnostics: [ParseDiagnostic] = []

        let version = tree.attribute("version") ?? "unknown"
        let standard = StandardUDDFInterpreter()
        let generator = standard.parseGenerator(tree, diagnostics: &diagnostics)
        let mixes = parseMixes(tree, diagnostics: &diagnostics)
        let sites = standard.parseSites(tree)
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
            mixes: mixes,
            sites: sites,
            dives: dives
        )

        return ParseResult(document: document, diagnostics: diagnostics)
    }

    // MARK: - Mixes

    /// Parse mixes. Shearwater uses compound IDs like `"OC1:32/00"`.
    func parseMixes(_ tree: XNode, diagnostics: inout [ParseDiagnostic]) -> [String: UDDFMix] {
        var mixes: [String: UDDFMix] = [:]

        let mixNodes = tree.query("gasdefinitions", "mix")
        for node in mixNodes {
            guard let id = node.attribute("id") else { continue }

            // Try to extract gas fractions from the compound ID (e.g., "OC1:32/00")
            let (o2, he) = extractGasFromId(id)
                ?? (node.doubleValue("o2") ?? 0.21, node.doubleValue("he") ?? 0.0)

            let mix = UDDFMix(
                id: id,
                name: node.stringValue("name"),
                o2: o2,
                he: he,
                ar: node.doubleValue("ar"),
                h2: node.doubleValue("h2")
            )
            mixes[id] = mix
        }

        return mixes
    }

    /// Extract O2/He fractions from Shearwater's compound mix ID.
    /// Format: `"OC1:32/00"` → o2=0.32, he=0.00
    /// Format: `"CC1:21/35"` → o2=0.21, he=0.35
    func extractGasFromId(_ id: String) -> (o2: Double, he: Double)? {
        // Match pattern like "OC1:32/00" or "CC1:21/35"
        guard let colonIdx = id.firstIndex(of: ":") else { return nil }
        let gasPart = id[id.index(after: colonIdx)...]
        let components = gasPart.split(separator: "/")
        guard components.count == 2,
              let o2Int = Int(components[0]),
              let heInt = Int(components[1]) else { return nil }
        return (Double(o2Int) / 100.0, Double(heInt) / 100.0)
    }

    /// Infer dive mode from Shearwater mix ref prefix.
    func inferDiveMode(from mixRef: String?) -> String? {
        guard let ref = mixRef else { return nil }
        if ref.range(of: #"^OC\d+:"#, options: .regularExpression) != nil {
            return "opencircuit"
        } else if ref.range(of: #"^CC\d+:"#, options: .regularExpression) != nil {
            return "closedcircuit"
        }
        return nil
    }

    // MARK: - Dives

    func parseDives(_ tree: XNode, knownSiteIds: Set<String>, mixes: [String: UDDFMix], diagnostics: inout [ParseDiagnostic]) -> [UDDFDive] {
        var dives: [UDDFDive] = []

        let diveNodes = tree.query("profiledata", "repetitiongroup", "dive")
        for node in diveNodes {
            let dive = parseSingleDive(node, knownSiteIds: knownSiteIds, mixes: mixes, diagnostics: &diagnostics)
            dives.append(dive)
        }

        return dives
    }

    func parseSingleDive(_ node: XNode, knownSiteIds: Set<String>, mixes: [String: UDDFMix], diagnostics: inout [ParseDiagnostic]) -> UDDFDive {
        let before = node.child("informationbeforedive")
        let after = node.child("informationafterdive")

        let siteRef = findSiteRef(before, knownSiteIds: knownSiteIds)
        let tanks = parseTankData(node)
        let waypoints = parseWaypoints(node.child("samples"), diagnostics: &diagnostics)
        let visibility = parseVisibility(after, diagnostics: &diagnostics)
        let notes = parseNotes(after)

        return UDDFDive(
            id: node.attribute("id"),
            number: before?.child("divenumber")?.textValue.flatMap { Int($0) },
            datetime: before?.stringValue("datetime"),
            surfaceInterval: before?.child("surfaceintervalbeforedive")?.doubleValue("passedtime"),
            surfacePressure: before?.doubleValue("surfacepressure"),
            siteRef: siteRef,
            greatestDepth: after?.doubleValue("greatestdepth"),
            averageDepth: after?.doubleValue("averagedepth"),
            duration: after?.doubleValue("diveduration"),
            visibility: visibility,
            notes: notes,
            tanks: tanks,
            waypoints: waypoints
        )
    }

    // MARK: - Site Ref

    /// Shearwater puts multiple <link> refs in informationbeforedive:
    /// profile, buddy, site, deco model, equipment. Match against known site IDs.
    func findSiteRef(_ before: XNode?, knownSiteIds: Set<String>) -> String? {
        guard let before else { return nil }
        let links = before.children("link")
        for link in links {
            if let ref = link.attribute("ref"), knownSiteIds.contains(ref) {
                return ref
            }
        }
        // Also check equipmentused sub-links are excluded
        let topLevelLinks = before.children("link")
        return topLevelLinks.first { link in
            guard let ref = link.attribute("ref") else { return false }
            return knownSiteIds.contains(ref)
        }?.attribute("ref")
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
                mixRef: mixRef,
                tankRef: nil,
                pressureBegin: cleanPressure(beginRaw),
                pressureEnd: cleanPressure(endRaw),
                volume: node.doubleValue("tankvolume")
            )
            tanks.append(tank)
        }

        return tanks
    }

    // MARK: - Waypoints

    func parseWaypoints(_ samples: XNode?, diagnostics: inout [ParseDiagnostic]) -> [UDDFWaypoint] {
        guard let samples else { return [] }
        var waypoints: [UDDFWaypoint] = []
        var currentMode: String?

        for wp in samples.children("waypoint") {
            let (tankPressure, tankRef) = parseTankPressure(wp)
            let switchMixRef = wp.child("switchmix")?.attribute("ref")

            // Dive mode: explicit from XML, or inferred from mix ref prefix
            let explicitMode = wp.child("divemode")?.attribute("type")
            let inferredMode = switchMixRef.flatMap { inferDiveMode(from: $0) }
            let diveMode = explicitMode ?? inferredMode ?? currentMode

            if let switchMixRef, let newMode = inferDiveMode(from: switchMixRef) {
                if let prevMode = currentMode, prevMode != newMode {
                    diagnostics.append(ParseDiagnostic(
                        level: .info,
                        message: "Mode switch detected: \(prevMode) → \(newMode) via mix \(switchMixRef)",
                        context: "waypoint \(wp.doubleValue("divetime") ?? 0)s"
                    ))
                }
                currentMode = newMode
            } else if let explicitMode {
                currentMode = explicitMode
            }

            let waypoint = UDDFWaypoint(
                time: wp.doubleValue("divetime") ?? 0,
                depth: wp.doubleValue("depth") ?? 0,
                temperature: wp.doubleValue("temperature"),
                tankPressure: tankPressure,
                tankRef: tankRef,
                switchMixRef: switchMixRef,
                diveMode: diveMode,
                calculatedPO2: wp.doubleValue("calculatedpo2"),
                measuredPO2: wp.doubleValue("measuredpo2"),
                setPO2: wp.child("setpo2")?.textValue.flatMap { Double($0) },
                cns: wp.doubleValue("cns"),
                ndl: wp.doubleValue("nodecotime"),
                ceiling: wp.doubleValue("decostop"),
                gradientFactor: wp.doubleValue("gradientfactor"),
                heading: wp.doubleValue("heading"),
                heartRate: wp.doubleValue("heartrate"),
                alarm: wp.stringValue("alarm")
            )
            waypoints.append(waypoint)
        }

        return waypoints
    }

    /// Parse tank pressure from waypoint, stripping sentinel values.
    func parseTankPressure(_ wp: XNode) -> (Double?, String?) {
        let tpNodes = wp.children("tankpressure")
        if tpNodes.isEmpty {
            return (nil, nil)
        }
        for tp in tpNodes {
            if let text = tp.textValue, let value = Double(text) {
                let cleaned = cleanPressure(value)
                if cleaned != nil {
                    return (cleaned, tp.attribute("ref"))
                }
            }
        }
        return (nil, tpNodes.first?.attribute("ref"))
    }

    // MARK: - Pressure Sentinel

    /// Strip Shearwater's sentinel value for "no data".
    func cleanPressure(_ value: Double?) -> Double? {
        guard let v = value else { return nil }
        if v == Self.pressureSentinel { return nil }
        return v
    }

    // MARK: - Visibility

    /// Parse freeform visibility string. Shearwater passes user-entered text.
    /// Regex: `(\d+\.?\d*)\s*(ft|feet|m|meters)?`
    func parseVisibility(_ after: XNode?, diagnostics: inout [ParseDiagnostic]) -> Double? {
        guard let text = after?.stringValue("visibility") else { return nil }

        // Try numeric first (standard UDDF)
        if let value = Double(text) {
            return value
        }

        // Freeform parsing
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

        // Check unit
        if match.range(at: 2).location != NSNotFound,
           let unitRange = Range(match.range(at: 2), in: text) {
            let unit = text[unitRange].lowercased()
            if unit == "ft" || unit == "feet" {
                return number * 0.3048  // feet to meters
            }
        }

        // No unit or meters — assume meters per UDDF spec
        return number
    }

    // MARK: - Notes

    func parseNotes(_ after: XNode?) -> String? {
        guard let notes = after?.child("notes") else { return nil }
        let paras = notes.children("para").compactMap { $0.textValue }
        // Filter out Shearwater metadata tags but preserve them for overflow
        let userNotes = paras.filter { !$0.hasPrefix("-Shearwater") }
        let joined = userNotes.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }
}
