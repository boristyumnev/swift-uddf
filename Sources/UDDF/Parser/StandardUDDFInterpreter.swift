import Foundation

/// Interprets spec-compliant UDDF 3.2.x files.
/// Generator-specific interpreters delegate to this for standard parsing.
public struct StandardUDDFInterpreter: UDDFInterpreting, Sendable {

    public init() {}

    public func interpret(tree: XNode) throws -> ParseResult {
        var diagnostics: [ParseDiagnostic] = []

        let version = tree.attribute("version") ?? "unknown"
        let generator = parseGenerator(tree, diagnostics: &diagnostics)
        let (owner, buddies) = parseDiver(tree, diagnostics: &diagnostics)
        let mixes = parseMixes(tree)
        let (sites, diveBases) = parseSites(tree, diagnostics: &diagnostics)
        let decoModels = parseDecoModels(tree)
        let dives = parseDives(tree, diagnostics: &diagnostics)

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
            decoModels: decoModels,
            dives: dives
        )

        return ParseResult(document: document, diagnostics: diagnostics)
    }

    // MARK: - Enum Parsing Helper

    /// Parse a raw string into an enum, emitting a diagnostic warning if the value is unrecognized.
    func parseEnum<E: RawRepresentable>(
        _ raw: String?,
        as type: E.Type,
        path: String,
        diagnostics: inout [ParseDiagnostic]
    ) -> E? where E.RawValue == String {
        guard let raw, !raw.isEmpty else { return nil }
        if let value = E(rawValue: raw) { return value }
        diagnostics.append(ParseDiagnostic(
            level: .warning,
            message: "Unknown \(path) value: \"\(raw)\"",
            context: path
        ))
        return nil
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
                serialNumber: dc.stringValue("serialnumber"),
                softwareVersion: dc.stringValue("softwareversion")
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

    func parseDiver(_ tree: XNode, diagnostics: inout [ParseDiagnostic]) -> (UDDFOwner?, [UDDFBuddy]) {
        guard let diver = tree.child("diver") else { return (nil, []) }

        // Owner
        let owner: UDDFOwner?
        if let ownerNode = diver.child("owner") {
            let personal = parsePersonalInfo(ownerNode.child("personal"), path: "diver/owner/personal", diagnostics: &diagnostics)
            let address = parseAddress(ownerNode.child("address"))
            let contact = parseContact(ownerNode.child("contact"))
            let equipment = parseEquipmentList(ownerNode.child("equipment"), diagnostics: &diagnostics)
            owner = UDDFOwner(
                personal: personal, address: address,
                contact: contact, equipment: equipment
            )
        } else {
            owner = nil
        }

        // Buddies
        var buddies: [UDDFBuddy] = []
        for buddyNode in diver.children("buddy") {
            guard let id = buddyNode.attribute("id") else { continue }
            let personal = parsePersonalInfo(buddyNode.child("personal"), path: "diver/buddy[\(id)]/personal", diagnostics: &diagnostics)
            let address = parseAddress(buddyNode.child("address"))
            let contact = parseContact(buddyNode.child("contact"))
            buddies.append(UDDFBuddy(
                id: id, personal: personal,
                address: address, contact: contact
            ))
        }

        return (owner, buddies)
    }

    func parsePersonalInfo(_ node: XNode?, path: String, diagnostics: inout [ParseDiagnostic]) -> UDDFPersonalInfo? {
        guard let node else { return nil }
        let firstName = node.stringValue("firstname")
        let middleName = node.stringValue("middlename")
        let lastName = node.stringValue("lastname")
        let honorific = node.stringValue("honorific")
        let sex: UDDFSex? = parseEnum(node.stringValue("sex"), as: UDDFSex.self, path: "\(path)/sex", diagnostics: &diagnostics)
        let birthdate = node.child("birthdate")?.stringValue("datetime")
        let height = node.doubleValue("height")
        let weight = node.doubleValue("weight")

        // Memberships
        var memberships: [UDDFMembership] = []
        for m in node.children("membership") {
            memberships.append(UDDFMembership(
                organization: m.attribute("org"),
                memberId: m.attribute("memberid")
            ))
        }

        guard firstName != nil || lastName != nil || middleName != nil
            || honorific != nil || sex != nil || birthdate != nil
            || height != nil || weight != nil || !memberships.isEmpty else {
            return nil
        }
        return UDDFPersonalInfo(
            firstName: firstName, middleName: middleName,
            lastName: lastName, honorific: honorific,
            sex: sex, birthdate: birthdate,
            height: height, weight: weight,
            memberships: memberships
        )
    }

    // MARK: - Address & Contact

    func parseAddress(_ node: XNode?) -> UDDFAddress? {
        guard let node else { return nil }
        let street = node.stringValue("street")
        let city = node.stringValue("city")
        let postcode = node.stringValue("postcode")
        let country = node.stringValue("country")
        let province = node.stringValue("province")
        guard street != nil || city != nil || postcode != nil
            || country != nil || province != nil else { return nil }
        return UDDFAddress(
            street: street, city: city, postcode: postcode,
            country: country, province: province
        )
    }

    func parseContact(_ node: XNode?) -> UDDFContact? {
        guard let node else { return nil }
        let phone = node.stringValue("phone")
        let mobilephone = node.stringValue("mobilephone")
        let fax = node.stringValue("fax")
        let email = node.stringValue("email")
        let homepage = node.stringValue("homepage")
        let language = node.stringValue("language")
        guard phone != nil || mobilephone != nil || fax != nil
            || email != nil || homepage != nil || language != nil else { return nil }
        return UDDFContact(
            phone: phone, mobilephone: mobilephone, fax: fax,
            email: email, homepage: homepage, language: language
        )
    }

    // MARK: - Equipment

    func parseEquipmentList(_ node: XNode?, diagnostics: inout [ParseDiagnostic]) -> UDDFEquipmentList? {
        guard let node else { return nil }
        var items: [UDDFEquipmentItem] = []

        // All known equipment element names
        let typeMap: [String: UDDFEquipmentType] = [
            "boots": .boots, "buoyancycontroldevice": .buoyancycontroldevice,
            "camera": .camera, "compass": .compass, "compressor": .compressor,
            "divecomputer": .divecomputer, "equipmentconfiguration": .equipmentconfiguration,
            "fins": .fins, "gloves": .gloves, "knife": .knife,
            "lead": .lead, "light": .light, "mask": .mask,
            "rebreather": .rebreather, "regulator": .regulator,
            "scooter": .scooter, "suit": .suit, "tank": .tank,
            "variouspieces": .variouspieces, "videocamera": .videocamera,
            "watch": .watch,
        ]

        for (elementName, equipType) in typeMap {
            for child in node.children(elementName) {
                guard let id = child.attribute("id") else { continue }
                let item = UDDFEquipmentItem(
                    type: equipType,
                    id: id,
                    name: child.stringValue("name"),
                    manufacturer: child.child("manufacturer")?.stringValue("name"),
                    model: child.stringValue("model"),
                    serialNumber: child.stringValue("serialnumber"),
                    softwareVersion: child.stringValue("softwareversion"),
                    notes: child.stringValue("notes"),
                    tankVolume: child.doubleValue("tankvolume"),
                    tankMaterial: parseEnum(child.stringValue("tankmaterial"), as: UDDFTankMaterial.self, path: "equipment/\(elementName)[\(id)]/tankmaterial", diagnostics: &diagnostics),
                    suitType: parseEnum(child.stringValue("suittype"), as: UDDFSuitType.self, path: "equipment/\(elementName)[\(id)]/suittype", diagnostics: &diagnostics)
                )
                items.append(item)
            }
        }

        guard !items.isEmpty else { return nil }
        return UDDFEquipmentList(items: items)
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
                h2: node.doubleValue("h2"),
                maximumPO2: node.doubleValue("maximumpo2"),
                maximumOperationDepth: node.doubleValue("maximumoperationdepth")
            )
            mixes[id] = mix
        }

        return mixes
    }

    // MARK: - Sites + DiveBases

    func parseSites(_ tree: XNode, diagnostics: inout [ParseDiagnostic]) -> ([String: UDDFSite], [UDDFDiveBase]) {
        var sites: [String: UDDFSite] = [:]
        var diveBases: [UDDFDiveBase] = []

        // Dive bases
        let baseNodes = tree.query("divesite", "divebase")
        for node in baseNodes {
            guard let id = node.attribute("id") else { continue }
            diveBases.append(UDDFDiveBase(
                id: id, name: node.stringValue("name"),
                address: parseAddress(node.child("address")),
                contact: parseContact(node.child("contact")),
                aliasname: node.stringValue("aliasname"),
                rating: node.child("rating")?.doubleValue("ratingvalue"),
                notes: parseNotes(node)
            ))
        }

        // Sites
        let siteNodes = tree.query("divesite", "site")
        for node in siteNodes {
            guard let id = node.attribute("id") else { continue }
            let geo = node.child("geography")
            let sitedata = node.child("sitedata")
            let notes = parseNotes(node)

            let site = UDDFSite(
                id: id,
                name: node.stringValue("name"),
                aliasname: node.stringValue("aliasname"),
                environment: parseEnum(node.stringValue("environment"), as: UDDFEnvironment.self, path: "divesite/site[\(id)]/environment", diagnostics: &diagnostics),
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
                rating: node.child("rating")?.doubleValue("ratingvalue"),
                notes: notes
            )
            sites[id] = site
        }

        return (sites, diveBases)
    }

    // MARK: - Deco Models

    func parseDecoModels(_ tree: XNode) -> [UDDFDecoModel] {
        var models: [UDDFDecoModel] = []

        let decoNodes = tree.children("decomodel")
        for decoNode in decoNodes {
            for buehlmann in decoNode.children("buehlmann") {
                guard let id = buehlmann.attribute("id") else { continue }
                models.append(UDDFDecoModel(
                    id: id,
                    name: "Buhlmann",
                    gradientFactorHigh: buehlmann.doubleValue("gfhigh"),
                    gradientFactorLow: buehlmann.doubleValue("gflow")
                ))
            }
        }

        return models
    }

    // MARK: - Dives

    func parseDives(_ tree: XNode, diagnostics: inout [ParseDiagnostic]) -> [UDDFDive] {
        var dives: [UDDFDive] = []

        let repGroups = tree.query("profiledata", "repetitiongroup")
        for group in repGroups {
            let groupId = group.attribute("id")
            for diveNode in group.children("dive") {
                let dive = parseSingleDive(diveNode, repetitionGroupId: groupId, diagnostics: &diagnostics)
                dives.append(dive)
            }
        }

        return dives
    }

    func parseSingleDive(_ node: XNode, repetitionGroupId: String? = nil, diagnostics: inout [ParseDiagnostic]) -> UDDFDive {
        let before = node.child("informationbeforedive")
        let after = node.child("informationafterdive")
        let diveId = node.attribute("id") ?? "?"
        let divePath = "dive[\(diveId)]"

        let siteRef = findSiteRef(before)
        let tanks = parseTankData(node)
        let waypoints = parseWaypoints(node.child("samples"), divePath: divePath, diagnostics: &diagnostics)

        // Before-dive fields
        let surfaceIntervalNode = before?.child("surfaceintervalbeforedive")
        let isInfinity = surfaceIntervalNode?.child("infinity") != nil ? true : nil
        let surfaceInterval = surfaceIntervalNode?.doubleValue("passedtime")

        // Link refs from informationbeforedive
        let allBeforeRefs = extractLinkRefs(before)

        // Equipment used refs + lead quantity
        let equipUsed = after?.child("equipmentused")
        let equipmentUsedRefs = extractLinkRefs(equipUsed)
        let leadQuantity = equipUsed?.doubleValue("leadquantity")

        // After-dive notes
        let notes = parseNotes(after)

        // Rating
        let rating = after?.child("rating")?.doubleValue("ratingvalue")

        // Surface interval after dive
        let siAfter = after?.child("surfaceintervalafterdive")?.doubleValue("passedtime")

        // Observations
        let observations = parseNotes(after?.child("observations"))

        // Symptoms
        let symptoms = parseNotes(after?.child("anysymptoms"))

        // Deco model ref from links
        let decoModelRef: String? = nil  // resolved by interpreter if needed

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
            apparatus: parseEnum(before?.stringValue("apparatus"), as: UDDFApparatus.self, path: "\(divePath)/informationbeforedive/apparatus", diagnostics: &diagnostics),
            platform: parseEnum(before?.stringValue("platform"), as: UDDFPlatform.self, path: "\(divePath)/informationbeforedive/platform", diagnostics: &diagnostics),
            purpose: parseEnum(before?.stringValue("purpose"), as: UDDFPurpose.self, path: "\(divePath)/informationbeforedive/purpose", diagnostics: &diagnostics),
            stateOfRest: parseEnum(before?.stringValue("stateofrestbeforedive"), as: UDDFStateOfRest.self, path: "\(divePath)/informationbeforedive/stateofrestbeforedive", diagnostics: &diagnostics),
            noSuit: before?.child("nosuit") != nil ? true : nil,
            price: before?.doubleValue("price"),
            siteRef: siteRef,
            buddyRefs: allBeforeRefs,
            decoModelRef: decoModelRef,
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
            current: parseEnum(after?.stringValue("current"), as: UDDFCurrent.self, path: "\(divePath)/informationafterdive/current", diagnostics: &diagnostics),
            thermalComfort: parseEnum(after?.stringValue("thermalcomfort"), as: UDDFThermalComfort.self, path: "\(divePath)/informationafterdive/thermalcomfort", diagnostics: &diagnostics),
            workload: parseEnum(after?.stringValue("workload"), as: UDDFWorkload.self, path: "\(divePath)/informationafterdive/workload", diagnostics: &diagnostics),
            program: parseEnum(after?.stringValue("program"), as: UDDFProgram.self, path: "\(divePath)/informationafterdive/program", diagnostics: &diagnostics),
            rating: rating,
            equipmentUsedRefs: equipmentUsedRefs,
            leadQuantity: leadQuantity,
            surfaceIntervalAfterDive: siAfter,
            observations: observations,
            symptoms: symptoms,
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

    func parseWaypoints(_ samples: XNode?, divePath: String = "dive", diagnostics: inout [ParseDiagnostic]) -> [UDDFWaypoint] {
        guard let samples else { return [] }
        var waypoints: [UDDFWaypoint] = []

        for wp in samples.children("waypoint") {
            let tankPressures = parseTankPressures(wp)
            let alarms = parseAlarms(wp, divePath: divePath, diagnostics: &diagnostics)
            let decoStops = parseDecoStops(wp, divePath: divePath, diagnostics: &diagnostics)
            let measuredPO2s = parseSensorReadings(wp, elementName: "measuredpo2")
            let batteryVoltages = parseSensorReadings(wp, elementName: "batteryvoltage")
            let scrubberReadings = parseSensorReadings(wp, elementName: "scrubber")
            let time = wp.doubleValue("divetime") ?? 0
            let wpPath = "\(divePath)/samples/waypoint[\(Int(time))s]"

            let waypoint = UDDFWaypoint(
                time: time,
                depth: wp.doubleValue("depth") ?? 0,
                temperature: wp.doubleValue("temperature"),
                tankPressures: tankPressures,
                switchMixRef: wp.child("switchmix")?.attribute("ref"),
                diveMode: parseEnum(wp.child("divemode")?.attribute("type"), as: UDDFDiveMode.self, path: "\(wpPath)/divemode", diagnostics: &diagnostics),
                calculatedPO2: wp.doubleValue("calculatedpo2"),
                measuredPO2s: measuredPO2s,
                setPO2: wp.child("setpo2")?.textValue.flatMap { Double($0) },
                setPO2SetBy: parseEnum(wp.child("setpo2")?.attribute("setby"), as: UDDFSetBySource.self, path: "\(wpPath)/setpo2/@setby", diagnostics: &diagnostics),
                cns: wp.doubleValue("cns"),
                ndl: wp.doubleValue("nodecotime"),
                decoStops: decoStops,
                gradientFactor: wp.doubleValue("gradientfactor"),
                setGFHigh: wp.doubleValue("setgfhigh"),
                setGFLow: wp.doubleValue("setgflow"),
                timeToSurface: wp.doubleValue("timetosurface"),
                heading: wp.doubleValue("heading"),
                heartRate: wp.doubleValue("heartrate") ?? wp.doubleValue("pulserate"),
                alarms: alarms,
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

    /// Parse sensor readings — reusable for measuredpo2, batteryvoltage, scrubber.
    func parseSensorReadings(_ wp: XNode, elementName: String) -> [UDDFSensorReading] {
        let nodes = wp.children(elementName)
        var readings: [UDDFSensorReading] = []
        for node in nodes {
            if let text = node.textValue, let value = Double(text) {
                readings.append(UDDFSensorReading(ref: node.attribute("ref"), value: value))
            }
        }
        return readings
    }

    /// Parse all <alarm> elements from a waypoint.
    func parseAlarms(_ wp: XNode, divePath: String = "dive", diagnostics: inout [ParseDiagnostic]) -> [UDDFAlarm] {
        let alarmNodes = wp.children("alarm")
        var alarms: [UDDFAlarm] = []
        for node in alarmNodes {
            let text = node.textValue
            let type: UDDFAlarmType? = parseEnum(text, as: UDDFAlarmType.self, path: "\(divePath)/samples/waypoint/alarm", diagnostics: &diagnostics)
            let level = node.attribute("level").flatMap { Double($0) }
            let tankRef = node.attribute("tankref")
            alarms.append(UDDFAlarm(type: type, message: text, level: level, tankRef: tankRef))
        }
        return alarms
    }

    /// Parse all <decostop> elements from a waypoint.
    func parseDecoStops(_ wp: XNode, divePath: String = "dive", diagnostics: inout [ParseDiagnostic]) -> [UDDFDecoStop] {
        let stopNodes = wp.children("decostop")
        var stops: [UDDFDecoStop] = []
        for node in stopNodes {
            let kind: UDDFDecoStopKind? = parseEnum(node.attribute("kind"), as: UDDFDecoStopKind.self, path: "\(divePath)/samples/waypoint/decostop/@kind", diagnostics: &diagnostics)
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

    func parseNotes(_ node: XNode?) -> String? {
        guard let node else { return nil }
        // Try <notes><para>...</para></notes> first
        let notesChild = node.child("notes") ?? node
        let paras = notesChild.children("para").compactMap { $0.textValue }
        if !paras.isEmpty {
            let joined = paras.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return joined.isEmpty ? nil : joined
        }
        // Fall back to direct text content in <notes>
        if let direct = notesChild.textValue, !direct.isEmpty {
            return direct
        }
        return nil
    }
}
