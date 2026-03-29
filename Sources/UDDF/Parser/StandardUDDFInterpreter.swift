import Foundation

/// Interprets spec-compliant UDDF 3.2.x files.
/// Generator-specific interpreters delegate to this for standard parsing.
public struct StandardUDDFInterpreter: UDDFInterpreting, Sendable {

    public init() {}

    public func interpret(tree: XNode) throws -> ParseResult {
        var diagnostics: [ParseDiagnostic] = []

        let version = tree.attribute("version") ?? "unknown"
        let generator = parseGenerator(tree, diagnostics: &diagnostics)
        let mixes = parseMixes(tree)
        let sites = parseSites(tree)
        let dives = parseDives(tree)

        diagnostics.insert(
            ParseDiagnostic(
                level: .info,
                message: "Detected \(generator.name) v\(generator.version ?? "?")",
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

    // MARK: - Generator

    func parseGenerator(_ tree: XNode, diagnostics: inout [ParseDiagnostic]) -> UDDFGenerator {
        let gen = tree.child("generator")

        // Dive computer from diver/owner/equipment/divecomputer
        let dc = tree.query("diver", "owner", "equipment", "divecomputer").first
        let diveComputer: UDDFDiveComputer?
        if let dc {
            diveComputer = UDDFDiveComputer(
                name: dc.stringValue("name"),
                model: dc.stringValue("model"),
                serialNumber: dc.stringValue("serialnumber")
            )
        } else {
            diveComputer = nil
        }

        return UDDFGenerator(
            name: gen?.stringValue("name") ?? "Unknown",
            version: gen?.stringValue("version"),
            manufacturer: gen?.child("manufacturer")?.stringValue("name"),
            diveComputer: diveComputer
        )
    }

    // MARK: - Mixes

    func parseMixes(_ tree: XNode) -> [String: UDDFMix] {
        var mixes: [String: UDDFMix] = [:]

        let mixNodes = tree.query("gasdefinitions", "mix")
        for node in mixNodes {
            guard let id = node.attribute("id") else { continue }
            let o2 = node.doubleValue("o2") ?? 0.21
            let he = node.doubleValue("he") ?? 0.0

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

    // MARK: - Sites

    func parseSites(_ tree: XNode) -> [String: UDDFSite] {
        var sites: [String: UDDFSite] = [:]

        let siteNodes = tree.query("divesite", "site")
        for node in siteNodes {
            guard let id = node.attribute("id") else { continue }
            let geo = node.child("geography")

            let site = UDDFSite(
                id: id,
                name: node.stringValue("name"),
                location: geo?.stringValue("location"),
                latitude: geo?.doubleValue("latitude"),
                longitude: geo?.doubleValue("longitude"),
                altitude: geo?.doubleValue("altitude"),
                country: geo?.child("address")?.stringValue("country")
                    ?? geo?.stringValue("country"),
                province: geo?.child("address")?.stringValue("province")
                    ?? geo?.stringValue("province")
            )
            sites[id] = site
        }

        return sites
    }

    // MARK: - Dives

    func parseDives(_ tree: XNode) -> [UDDFDive] {
        var dives: [UDDFDive] = []

        let diveNodes = tree.query("profiledata", "repetitiongroup", "dive")
        for node in diveNodes {
            let dive = parseSingleDive(node)
            dives.append(dive)
        }

        return dives
    }

    func parseSingleDive(_ node: XNode) -> UDDFDive {
        let before = node.child("informationbeforedive")
        let after = node.child("informationafterdive")

        // Site ref from <link ref="..."> — need to find the site link
        // Links can reference sites, buddies, deco models, etc.
        // The site ref is the one that matches a known site ID.
        // For now, collect all link refs and let the mapper resolve.
        let siteRef = findSiteRef(before)

        // Tank data
        let tanks = parseTankData(node)

        // Waypoints
        let waypoints = parseWaypoints(node.child("samples"))

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
            visibility: parseVisibility(after),
            notes: parseNotes(after),
            tanks: tanks,
            waypoints: waypoints
        )
    }

    /// Find site ref from <link> elements in informationbeforedive.
    /// UDDF uses <link ref="..."/> for various cross-references.
    /// The site ref is typically the one that matches a site ID.
    func findSiteRef(_ before: XNode?) -> String? {
        guard let before else { return nil }
        let links = before.children("link")
        // Return the first link ref that looks like a site reference.
        // In practice, we return all refs and let the mapper match against known sites.
        // For now, return the first link that isn't clearly a deco model or buddy.
        // A more robust approach: the interpreter has access to known site IDs from parseSites().
        // We'll use a simple heuristic: return the first link ref.
        // The Shearwater interpreter can override this with better logic.
        return links.first?.attribute("ref")
    }

    // MARK: - Tank Data

    func parseTankData(_ diveNode: XNode) -> [UDDFTankData] {
        var tanks: [UDDFTankData] = []

        let tankNodes = diveNode.children("tankdata")
        for node in tankNodes {
            let mixRef = node.children("link").first?.attribute("ref")
            let tank = UDDFTankData(
                mixRef: mixRef,
                tankRef: nil,
                pressureBegin: node.doubleValue("tankpressurebegin"),
                pressureEnd: node.doubleValue("tankpressureend"),
                volume: node.doubleValue("tankvolume")
            )
            tanks.append(tank)
        }

        return tanks
    }

    // MARK: - Waypoints

    func parseWaypoints(_ samples: XNode?) -> [UDDFWaypoint] {
        guard let samples else { return [] }
        var waypoints: [UDDFWaypoint] = []

        for wp in samples.children("waypoint") {
            // Tank pressure — may have multiple with different refs, take first non-sentinel
            let (tankPressure, tankRef) = parseTankPressure(wp)

            let waypoint = UDDFWaypoint(
                time: wp.doubleValue("divetime") ?? 0,
                depth: wp.doubleValue("depth") ?? 0,
                temperature: wp.doubleValue("temperature"),
                tankPressure: tankPressure,
                tankRef: tankRef,
                switchMixRef: wp.child("switchmix")?.attribute("ref"),
                diveMode: wp.child("divemode")?.attribute("type"),
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

    /// Parse tank pressure from waypoint. May have multiple <tankpressure ref="T1">
    /// elements. Returns the first valid (non-sentinel) pressure and its ref.
    func parseTankPressure(_ wp: XNode) -> (Double?, String?) {
        let tpNodes = wp.children("tankpressure")
        if tpNodes.isEmpty {
            return (nil, nil)
        }
        // Return first tank pressure with a value
        for tp in tpNodes {
            if let text = tp.textValue, let value = Double(text) {
                return (value, tp.attribute("ref"))
            }
        }
        return (nil, tpNodes.first?.attribute("ref"))
    }

    // MARK: - Visibility

    /// Standard UDDF: visibility is a real number in meters.
    /// Override in generator-specific interpreters for freeform parsing.
    func parseVisibility(_ after: XNode?) -> Double? {
        after?.doubleValue("visibility")
    }

    // MARK: - Notes

    func parseNotes(_ after: XNode?) -> String? {
        guard let notes = after?.child("notes") else { return nil }
        // UDDF notes are wrapped in <para> elements
        let paras = notes.children("para").compactMap { $0.textValue }
        let joined = paras.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }
}
