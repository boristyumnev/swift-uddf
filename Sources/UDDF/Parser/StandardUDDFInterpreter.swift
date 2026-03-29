import Foundation

/// Interprets spec-compliant UDDF 3.2.x files.
/// Generator-specific interpreters delegate to this for standard parsing.
public struct StandardUDDFInterpreter: UDDFInterpreting, Sendable {

    public init() {}

    public func interpret(tree: XNode) throws -> ParseResult {
        var diagnostics: [ParseDiagnostic] = []

        let version = tree.attribute("version") ?? "unknown"
        let generator = parseGenerator(tree, diagnostics: &diagnostics)
        let (owner, buddies) = parseDiver(tree)
        let mixes = parseMixes(tree)
        let (sites, diveBases) = parseSites(tree)
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
            owner: owner,
            buddies: buddies,
            mixes: mixes,
            sites: sites,
            diveBases: diveBases,
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
            type: gen?.stringValue("type"),
            version: gen?.stringValue("version"),
            datetime: gen?.stringValue("datetime"),
            manufacturer: gen?.child("manufacturer")?.stringValue("name"),
            diveComputer: diveComputer
        )
    }

    // MARK: - Diver (Owner + Buddies)

    func parseDiver(_ tree: XNode) -> (UDDFOwner?, [UDDFBuddy]) {
        guard let diver = tree.child("diver") else { return (nil, []) }

        // Owner
        let owner: UDDFOwner?
        if let ownerNode = diver.child("owner") {
            let personal = parsePersonalInfo(ownerNode.child("personal"))
            let dc = ownerNode.query("equipment", "divecomputer").first
            let equipment: UDDFEquipmentList?
            if let dc {
                equipment = UDDFEquipmentList(
                    diveComputer: UDDFDiveComputer(
                        name: dc.stringValue("name"),
                        model: dc.stringValue("model"),
                        serialNumber: dc.stringValue("serialnumber")
                    )
                )
            } else {
                equipment = nil
            }
            owner = UDDFOwner(personal: personal, equipment: equipment)
        } else {
            owner = nil
        }

        // Buddies
        var buddies: [UDDFBuddy] = []
        for buddyNode in diver.children("buddy") {
            guard let id = buddyNode.attribute("id") else { continue }
            let personal = parsePersonalInfo(buddyNode.child("personal"))
            buddies.append(UDDFBuddy(id: id, personal: personal))
        }

        return (owner, buddies)
    }

    func parsePersonalInfo(_ node: XNode?) -> UDDFPersonalInfo? {
        guard let node else { return nil }
        let firstName = node.stringValue("firstname")
        let middleName = node.stringValue("middlename")
        let lastName = node.stringValue("lastname")
        let sex = node.stringValue("sex").flatMap { UDDFSex(rawValue: $0) }
        let birthdate = node.child("birthdate")?.stringValue("datetime")

        guard firstName != nil || lastName != nil || middleName != nil || sex != nil || birthdate != nil else {
            return nil
        }
        return UDDFPersonalInfo(firstName: firstName, middleName: middleName, lastName: lastName, sex: sex, birthdate: birthdate)
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
                n2: node.doubleValue("n2"),
                he: he,
                ar: node.doubleValue("ar"),
                h2: node.doubleValue("h2")
            )
            mixes[id] = mix
        }

        return mixes
    }

    // MARK: - Sites + DiveBases

    func parseSites(_ tree: XNode) -> ([String: UDDFSite], [UDDFDiveBase]) {
        var sites: [String: UDDFSite] = [:]
        var diveBases: [UDDFDiveBase] = []

        // Dive bases
        let baseNodes = tree.query("divesite", "divebase")
        for node in baseNodes {
            guard let id = node.attribute("id") else { continue }
            diveBases.append(UDDFDiveBase(id: id, name: node.stringValue("name")))
        }

        // Sites
        let siteNodes = tree.query("divesite", "site")
        for node in siteNodes {
            guard let id = node.attribute("id") else { continue }
            let geo = node.child("geography")
            let sitedata = node.child("sitedata")

            // Notes
            let notes: String?
            if let notesNode = node.child("notes") {
                let paras = notesNode.children("para").compactMap { $0.textValue }
                let joined = paras.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                notes = joined.isEmpty ? nil : joined
            } else {
                notes = nil
            }

            let site = UDDFSite(
                id: id,
                name: node.stringValue("name"),
                environment: node.stringValue("environment").flatMap { UDDFEnvironment(rawValue: $0) },
                location: geo?.stringValue("location"),
                latitude: geo?.doubleValue("latitude"),
                longitude: geo?.doubleValue("longitude"),
                altitude: geo?.doubleValue("altitude"),
                country: geo?.child("address")?.stringValue("country")
                    ?? geo?.stringValue("country"),
                province: geo?.child("address")?.stringValue("province")
                    ?? geo?.stringValue("province"),
                maximumDepth: sitedata?.doubleValue("maximumdepth"),
                minimumDepth: sitedata?.doubleValue("minimumdepth"),
                density: sitedata?.doubleValue("density"),
                bottom: sitedata?.stringValue("bottom"),
                notes: notes
            )
            sites[id] = site
        }

        return (sites, diveBases)
    }

    // MARK: - Dives

    func parseDives(_ tree: XNode) -> [UDDFDive] {
        var dives: [UDDFDive] = []

        let repGroups = tree.query("profiledata", "repetitiongroup")
        for group in repGroups {
            let groupId = group.attribute("id")
            for diveNode in group.children("dive") {
                let dive = parseSingleDive(diveNode, repetitionGroupId: groupId)
                dives.append(dive)
            }
        }

        return dives
    }

    func parseSingleDive(_ node: XNode, repetitionGroupId: String? = nil) -> UDDFDive {
        let before = node.child("informationbeforedive")
        let after = node.child("informationafterdive")

        let siteRef = findSiteRef(before)
        let tanks = parseTankData(node)
        let waypoints = parseWaypoints(node.child("samples"))

        // Before-dive fields
        let surfaceIntervalNode = before?.child("surfaceintervalbeforedive")
        let isInfinity = surfaceIntervalNode?.child("infinity") != nil ? true : nil
        let surfaceInterval = surfaceIntervalNode?.doubleValue("passedtime")

        // Link refs from informationbeforedive
        let allBeforeRefs = extractLinkRefs(before)

        // Equipment used refs from informationafterdive
        let equipmentUsedRefs = extractLinkRefs(after?.child("equipmentused"))

        // After-dive notes
        let notes = parseNotes(after)

        // Rating
        let rating = after?.child("rating")?.doubleValue("ratingvalue")

        // Surface interval after dive
        let siAfter = after?.child("surfaceintervalafterdive")?.doubleValue("passedtime")

        return UDDFDive(
            id: node.attribute("id"),
            repetitionGroupId: repetitionGroupId,
            // before
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
            // after
            greatestDepth: after?.doubleValue("greatestdepth"),
            averageDepth: after?.doubleValue("averagedepth"),
            duration: after?.doubleValue("diveduration"),
            lowestTemperature: after?.doubleValue("lowesttemperature"),
            highestPO2: after?.doubleValue("highestpo2"),
            visibility: parseVisibility(after),
            desaturationTime: after?.doubleValue("desaturationtime"),
            noFlightTime: after?.doubleValue("noflighttime"),
            pressureDrop: after?.doubleValue("pressuredrop"),
            current: after?.stringValue("current").flatMap { UDDFCurrent(rawValue: $0) },
            thermalComfort: after?.stringValue("thermalcomfort").flatMap { UDDFThermalComfort(rawValue: $0) },
            workload: after?.stringValue("workload").flatMap { UDDFWorkload(rawValue: $0) },
            program: after?.stringValue("program").flatMap { UDDFProgram(rawValue: $0) },
            rating: rating,
            equipmentUsedRefs: equipmentUsedRefs,
            surfaceIntervalAfterDive: siAfter,
            notes: notes,
            tanks: tanks,
            waypoints: waypoints
        )
    }

    /// Extract all link refs from a node.
    func extractLinkRefs(_ node: XNode?) -> [String] {
        guard let node else { return [] }
        return node.children("link").compactMap { $0.attribute("ref") }
    }

    /// Find site ref from <link> elements in informationbeforedive.
    func findSiteRef(_ before: XNode?) -> String? {
        guard let before else { return nil }
        let links = before.children("link")
        return links.first?.attribute("ref")
    }

    // MARK: - Tank Data

    func parseTankData(_ diveNode: XNode) -> [UDDFTankData] {
        var tanks: [UDDFTankData] = []

        let tankNodes = diveNode.children("tankdata")
        for node in tankNodes {
            let linkRefs = node.children("link").compactMap { $0.attribute("ref") }
            let mixRef = linkRefs.first

            let tank = UDDFTankData(
                id: node.attribute("id"),
                mixRef: mixRef,
                pressureBegin: node.doubleValue("tankpressurebegin"),
                pressureEnd: node.doubleValue("tankpressureend"),
                volume: node.doubleValue("tankvolume"),
                breathingConsumptionVolume: node.doubleValue("breathingconsumptionvolume")
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
            let tankPressures = parseTankPressures(wp)
            let alarms = parseAlarms(wp)
            let decoStops = parseDecoStops(wp)

            let waypoint = UDDFWaypoint(
                time: wp.doubleValue("divetime") ?? 0,
                depth: wp.doubleValue("depth") ?? 0,
                temperature: wp.doubleValue("temperature"),
                tankPressures: tankPressures,
                switchMixRef: wp.child("switchmix")?.attribute("ref"),
                diveMode: wp.child("divemode")?.attribute("type").flatMap { UDDFDiveMode(rawValue: $0) },
                calculatedPO2: wp.doubleValue("calculatedpo2"),
                measuredPO2: wp.doubleValue("measuredpo2"),
                setPO2: wp.child("setpo2")?.textValue.flatMap { Double($0) },
                setPO2SetBy: wp.child("setpo2")?.attribute("setby").flatMap { UDDFSetBySource(rawValue: $0) },
                cns: wp.doubleValue("cns"),
                ndl: wp.doubleValue("nodecotime"),
                decoStops: decoStops,
                gradientFactor: wp.doubleValue("gradientfactor"),
                heading: wp.doubleValue("heading"),
                heartRate: wp.doubleValue("heartrate") ?? wp.doubleValue("pulserate"),
                alarms: alarms,
                otu: wp.doubleValue("otu"),
                bodyTemperature: wp.doubleValue("bodytemperature"),
                batteryChargeCondition: wp.doubleValue("batterychargecondition"),
                setMarker: wp.child("setmarker") != nil ? true : nil,
                remainingBottomTime: wp.doubleValue("remainingbottomtime"),
                remainingO2Time: wp.doubleValue("remainingo2time")
            )
            waypoints.append(waypoint)
        }

        return waypoints
    }

    /// Parse all <tankpressure> elements from a waypoint.
    func parseTankPressures(_ wp: XNode) -> [UDDFTankPressure] {
        let tpNodes = wp.children("tankpressure")
        var pressures: [UDDFTankPressure] = []
        for tp in tpNodes {
            if let text = tp.textValue, let value = Double(text) {
                pressures.append(UDDFTankPressure(ref: tp.attribute("ref"), value: value))
            }
        }
        return pressures
    }

    /// Parse all <alarm> elements from a waypoint.
    func parseAlarms(_ wp: XNode) -> [UDDFAlarm] {
        let alarmNodes = wp.children("alarm")
        var alarms: [UDDFAlarm] = []
        for node in alarmNodes {
            let text = node.textValue
            let type = text.flatMap { UDDFAlarmType(rawValue: $0) }
            alarms.append(UDDFAlarm(type: type, message: text))
        }
        return alarms
    }

    /// Parse all <decostop> elements from a waypoint.
    func parseDecoStops(_ wp: XNode) -> [UDDFDecoStop] {
        let stopNodes = wp.children("decostop")
        var stops: [UDDFDecoStop] = []
        for node in stopNodes {
            let kind = node.attribute("kind").flatMap { UDDFDecoStopKind(rawValue: $0) }
            let depth = node.attribute("decodepth").flatMap { Double($0) }
                ?? node.doubleValue("decodepth")
            let duration = node.attribute("duration").flatMap { Double($0) }
                ?? node.doubleValue("duration")
            stops.append(UDDFDecoStop(kind: kind, depth: depth, duration: duration))
        }
        return stops
    }

    // MARK: - Visibility

    /// Standard UDDF: visibility is a real number in meters.
    func parseVisibility(_ after: XNode?) -> Double? {
        after?.doubleValue("visibility")
    }

    // MARK: - Notes

    func parseNotes(_ after: XNode?) -> String? {
        guard let notes = after?.child("notes") else { return nil }
        let paras = notes.children("para").compactMap { $0.textValue }
        let joined = paras.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
    }
}
