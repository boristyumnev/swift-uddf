import Foundation

/// Walks a UDDFDocument model tree and emits elements in UDDF 3.2.3 spec order.
struct UDDFDocumentWriter {

    func write(document: UDDFDocument, generator: UDDFGenerator, builder: XMLBuilder) {
        builder.element("uddf", attributes: [("version", document.version)]) {
            writeGenerator(generator, builder: builder)
            writeMixes(document.mixes, builder: builder)
            writeDiver(owner: document.owner, buddies: document.buddies, builder: builder)
            writeSites(sites: document.sites, diveBases: document.diveBases, builder: builder)
            writeDecoModels(document.decoModels, builder: builder)
            writeDives(document.dives, builder: builder)
            writeOverflow(document.overflow, builder: builder)
        }
    }

    // MARK: - Generator

    private func writeGenerator(_ gen: UDDFGenerator, builder: XMLBuilder) {
        builder.element("generator") {
            builder.element("name", text: gen.name)
            builder.optionalElement("type", text: gen.type)
            if let mfr = gen.manufacturer {
                builder.element("manufacturer") {
                    builder.element("name", text: mfr)
                }
            }
            builder.optionalElement("version", text: gen.version)
            builder.optionalElement("datetime", text: gen.datetime)
        }
    }

    // MARK: - Mixes

    private func writeMixes(_ mixes: [String: UDDFMix], builder: XMLBuilder) {
        guard !mixes.isEmpty else { return }
        builder.element("gasdefinitions") {
            for (_, mix) in mixes.sorted(by: { $0.key < $1.key }) {
                builder.element("mix", attributes: [("id", mix.id)]) {
                    builder.optionalElement("name", text: mix.name)
                    builder.element("o2", text: "\(mix.o2)")
                    if let n2 = mix.n2 { builder.element("n2", text: "\(n2)") }
                    builder.element("he", text: "\(mix.he)")
                    if let ar = mix.ar { builder.element("ar", text: "\(ar)") }
                    if let h2 = mix.h2 { builder.element("h2", text: "\(h2)") }
                    builder.optionalElement("maximumpo2", double: mix.maximumPO2)
                    builder.optionalElement("maximumoperationdepth", double: mix.maximumOperationDepth)
                }
            }
        }
    }

    // MARK: - Diver

    private func writeDiver(owner: UDDFOwner?, buddies: [UDDFBuddy], builder: XMLBuilder) {
        guard owner != nil || !buddies.isEmpty else { return }
        builder.element("diver") {
            if let owner {
                builder.element("owner") {
                    writePersonalInfo(owner.personal, builder: builder)
                    writeAddress(owner.address, builder: builder)
                    writeContact(owner.contact, builder: builder)
                    writeEquipment(owner.equipment, builder: builder)
                }
            }
            for buddy in buddies {
                builder.element("buddy", attributes: [("id", buddy.id)]) {
                    writePersonalInfo(buddy.personal, builder: builder)
                    writeAddress(buddy.address, builder: builder)
                    writeContact(buddy.contact, builder: builder)
                }
            }
        }
    }

    private func writePersonalInfo(_ info: UDDFPersonalInfo?, builder: XMLBuilder) {
        guard let info else { return }
        builder.element("personal") {
            builder.optionalElement("firstname", text: info.firstName)
            builder.optionalElement("middlename", text: info.middleName)
            builder.optionalElement("lastname", text: info.lastName)
            builder.optionalElement("honorific", text: info.honorific)
            if let sex = info.sex { builder.element("sex", text: sex.rawValue) }
            if let birthdate = info.birthdate {
                builder.element("birthdate") {
                    builder.element("datetime", text: birthdate)
                }
            }
            builder.optionalElement("height", double: info.height)
            builder.optionalElement("weight", double: info.weight)
            for m in info.memberships {
                var attrs: [(String, String)] = []
                if let org = m.organization { attrs.append(("org", org)) }
                if let mid = m.memberId { attrs.append(("memberid", mid)) }
                builder.emptyElement("membership", attributes: attrs)
            }
        }
    }

    private func writeAddress(_ addr: UDDFAddress?, builder: XMLBuilder) {
        guard let addr else { return }
        builder.element("address") {
            builder.optionalElement("street", text: addr.street)
            builder.optionalElement("city", text: addr.city)
            builder.optionalElement("postcode", text: addr.postcode)
            builder.optionalElement("country", text: addr.country)
            builder.optionalElement("province", text: addr.province)
        }
    }

    private func writeContact(_ contact: UDDFContact?, builder: XMLBuilder) {
        guard let contact else { return }
        builder.element("contact") {
            builder.optionalElement("language", text: contact.language)
            builder.optionalElement("phone", text: contact.phone)
            builder.optionalElement("mobilephone", text: contact.mobilephone)
            builder.optionalElement("fax", text: contact.fax)
            builder.optionalElement("email", text: contact.email)
            builder.optionalElement("homepage", text: contact.homepage)
        }
    }

    private func writeEquipment(_ equipment: UDDFEquipmentList?, builder: XMLBuilder) {
        guard let equipment, !equipment.items.isEmpty else { return }
        builder.element("equipment") {
            for item in equipment.items {
                var attrs: [(String, String)] = [("id", item.id)]
                builder.element(item.type.rawValue, attributes: attrs) {
                    builder.optionalElement("name", text: item.name)
                    if let mfr = item.manufacturer {
                        builder.element("manufacturer") {
                            builder.element("name", text: mfr)
                        }
                    }
                    builder.optionalElement("model", text: item.model)
                    builder.optionalElement("serialnumber", text: item.serialNumber)
                    builder.optionalElement("softwareversion", text: item.softwareVersion)
                    builder.optionalElement("tankvolume", double: item.tankVolume)
                    if let tm = item.tankMaterial { builder.element("tankmaterial", text: tm.rawValue) }
                    if let st = item.suitType { builder.element("suittype", text: st.rawValue) }
                    builder.optionalElement("notes", text: item.notes)
                }
            }
        }
    }

    // MARK: - Sites

    private func writeSites(sites: [String: UDDFSite], diveBases: [UDDFDiveBase], builder: XMLBuilder) {
        guard !sites.isEmpty || !diveBases.isEmpty else { return }
        builder.element("divesite") {
            for base in diveBases {
                builder.element("divebase", attributes: [("id", base.id)]) {
                    builder.optionalElement("name", text: base.name)
                    writeAddress(base.address, builder: builder)
                    writeContact(base.contact, builder: builder)
                    builder.optionalElement("aliasname", text: base.aliasname)
                    if let r = base.rating {
                        builder.element("rating") { builder.element("ratingvalue", text: "\(r)") }
                    }
                    writeNotes(base.notes, builder: builder)
                }
            }
            for (_, site) in sites.sorted(by: { $0.key < $1.key }) {
                builder.element("site", attributes: [("id", site.id)]) {
                    builder.optionalElement("name", text: site.name)
                    builder.optionalElement("aliasname", text: site.aliasname)
                    if let env = site.environment { builder.element("environment", text: env.rawValue) }
                    if site.location != nil || site.latitude != nil || site.longitude != nil
                        || site.altitude != nil || site.country != nil || site.province != nil {
                        builder.element("geography") {
                            builder.optionalElement("location", text: site.location)
                            builder.optionalElement("latitude", double: site.latitude)
                            builder.optionalElement("longitude", double: site.longitude)
                            builder.optionalElement("altitude", double: site.altitude)
                            builder.optionalElement("country", text: site.country)
                            builder.optionalElement("province", text: site.province)
                        }
                    }
                    if site.maximumDepth != nil || site.minimumDepth != nil
                        || site.density != nil || site.bottom != nil {
                        builder.element("sitedata") {
                            builder.optionalElement("maximumdepth", double: site.maximumDepth)
                            builder.optionalElement("minimumdepth", double: site.minimumDepth)
                            builder.optionalElement("density", double: site.density)
                            builder.optionalElement("bottom", text: site.bottom)
                        }
                    }
                    if let r = site.rating {
                        builder.element("rating") { builder.element("ratingvalue", text: "\(r)") }
                    }
                    writeNotes(site.notes, builder: builder)
                    writeOverflow(site.overflow, builder: builder)
                }
            }
        }
    }

    // MARK: - Deco Models

    private func writeDecoModels(_ models: [UDDFDecoModel], builder: XMLBuilder) {
        for model in models {
            builder.element("decomodel") {
                var attrs: [(String, String)] = [("id", model.id)]
                builder.element("buehlmann", attributes: attrs) {
                    builder.optionalElement("gfhigh", double: model.gradientFactorHigh)
                    builder.optionalElement("gflow", double: model.gradientFactorLow)
                }
            }
        }
    }

    // MARK: - Dives

    private func writeDives(_ dives: [UDDFDive], builder: XMLBuilder) {
        guard !dives.isEmpty else { return }
        builder.element("profiledata") {
            // Group dives by repetition group
            var groups: [(id: String?, dives: [UDDFDive])] = []
            var currentGroupId: String? = dives.first?.repetitionGroupId
            var currentGroup: [UDDFDive] = []

            for dive in dives {
                if dive.repetitionGroupId != currentGroupId && !currentGroup.isEmpty {
                    groups.append((id: currentGroupId, dives: currentGroup))
                    currentGroup = []
                    currentGroupId = dive.repetitionGroupId
                }
                currentGroup.append(dive)
            }
            if !currentGroup.isEmpty {
                groups.append((id: currentGroupId, dives: currentGroup))
            }

            for group in groups {
                var attrs: [(String, String)] = []
                if let gid = group.id { attrs.append(("id", gid)) }
                builder.element("repetitiongroup", attributes: attrs) {
                    for dive in group.dives {
                        writeSingleDive(dive, builder: builder)
                    }
                }
            }
        }
    }

    private func writeSingleDive(_ dive: UDDFDive, builder: XMLBuilder) {
        var attrs: [(String, String)] = []
        if let id = dive.id { attrs.append(("id", id)) }
        builder.element("dive", attributes: attrs) {
            writeBeforeDive(dive, builder: builder)
            writeTankData(dive.tanks, builder: builder)
            writeWaypoints(dive.waypoints, builder: builder)
            writeAfterDive(dive, builder: builder)
            writeOverflow(dive.overflow, builder: builder)
        }
    }

    private func writeBeforeDive(_ dive: UDDFDive, builder: XMLBuilder) {
        builder.element("informationbeforedive") {
            builder.optionalElement("datetime", text: dive.datetime)
            builder.optionalElement("divenumber", int: dive.number)
            builder.optionalElement("divenumberofday", int: dive.divenumberOfDay)
            builder.optionalElement("internaldivenumber", int: dive.internalDiveNumber)
            builder.optionalElement("altitude", double: dive.altitude)
            builder.optionalElement("surfacepressure", double: dive.surfacePressure)
            builder.optionalElement("airtemperature", double: dive.airTemperature)

            // Surface interval
            if dive.surfaceIntervalIsInfinity == true {
                builder.element("surfaceintervalbeforedive") {
                    builder.emptyElement("infinity")
                }
            } else if let si = dive.surfaceInterval {
                builder.element("surfaceintervalbeforedive") {
                    builder.element("passedtime", text: "\(si)")
                }
            }

            if let app = dive.apparatus { builder.element("apparatus", text: app.rawValue) }
            if let plat = dive.platform { builder.element("platform", text: plat.rawValue) }
            if let purp = dive.purpose { builder.element("purpose", text: purp.rawValue) }
            if let rest = dive.stateOfRest { builder.element("stateofrestbeforedive", text: rest.rawValue) }
            if dive.noSuit == true { builder.emptyElement("nosuit") }
            builder.optionalElement("price", double: dive.price)

            // Link refs (site, buddies, equipment, deco model)
            if let siteRef = dive.siteRef {
                builder.emptyElement("link", attributes: [("ref", siteRef)])
            }
            for ref in dive.buddyRefs {
                builder.emptyElement("link", attributes: [("ref", ref)])
            }
            for ref in dive.equipmentRefs {
                builder.emptyElement("link", attributes: [("ref", ref)])
            }
            if let decoRef = dive.decoModelRef {
                builder.emptyElement("link", attributes: [("ref", decoRef)])
            }
        }
    }

    private func writeTankData(_ tanks: [UDDFTankData], builder: XMLBuilder) {
        for tank in tanks {
            var attrs: [(String, String)] = []
            if let id = tank.id { attrs.append(("id", id)) }
            builder.element("tankdata", attributes: attrs) {
                if let mixRef = tank.mixRef {
                    builder.emptyElement("link", attributes: [("ref", mixRef)])
                }
                if let tankRef = tank.tankRef {
                    builder.emptyElement("link", attributes: [("ref", tankRef)])
                }
                builder.optionalElement("tankvolume", double: tank.volume)
                builder.optionalElement("tankpressurebegin", double: tank.pressureBegin)
                builder.optionalElement("tankpressureend", double: tank.pressureEnd)
                builder.optionalElement("breathingconsumptionvolume", double: tank.breathingConsumptionVolume)
            }
        }
    }

    private func writeWaypoints(_ waypoints: [UDDFWaypoint], builder: XMLBuilder) {
        guard !waypoints.isEmpty else { return }
        builder.element("samples") {
            for wp in waypoints {
                builder.element("waypoint") {
                    builder.element("divetime", text: "\(wp.time)")
                    builder.element("depth", text: "\(wp.depth)")
                    builder.optionalElement("temperature", double: wp.temperature)

                    // Gas switch
                    if let mixRef = wp.switchMixRef {
                        builder.emptyElement("switchmix", attributes: [("ref", mixRef)])
                    }

                    // Dive mode
                    if let mode = wp.diveMode {
                        builder.emptyElement("divemode", attributes: [("type", mode.rawValue)])
                    }

                    // PO2
                    builder.optionalElement("calculatedpo2", double: wp.calculatedPO2)
                    for reading in wp.measuredPO2s {
                        var attrs: [(String, String)] = []
                        if let ref = reading.ref { attrs.append(("ref", ref)) }
                        builder.element("measuredpo2", text: "\(reading.value)", attributes: attrs)
                    }

                    // Setpoint
                    if let setPO2 = wp.setPO2 {
                        var attrs: [(String, String)] = []
                        if let setBy = wp.setPO2SetBy { attrs.append(("setby", setBy.rawValue)) }
                        builder.element("setpo2", text: "\(setPO2)", attributes: attrs)
                    }

                    // Tank pressures
                    for tp in wp.tankPressures {
                        var attrs: [(String, String)] = []
                        if let ref = tp.ref { attrs.append(("ref", ref)) }
                        builder.element("tankpressure", text: "\(tp.value)", attributes: attrs)
                    }

                    // Decompression
                    builder.optionalElement("cns", double: wp.cns)
                    builder.optionalElement("nodecotime", double: wp.ndl)
                    for stop in wp.decoStops {
                        var attrs: [(String, String)] = []
                        if let kind = stop.kind { attrs.append(("kind", kind.rawValue)) }
                        if let depth = stop.depth { attrs.append(("decodepth", "\(depth)")) }
                        if let dur = stop.duration { attrs.append(("duration", "\(dur)")) }
                        builder.emptyElement("decostop", attributes: attrs)
                    }

                    builder.optionalElement("gradientfactor", double: wp.gradientFactor)
                    builder.optionalElement("setgfhigh", double: wp.setGFHigh)
                    builder.optionalElement("setgflow", double: wp.setGFLow)
                    builder.optionalElement("timetosurface", double: wp.timeToSurface)

                    // Monitoring
                    builder.optionalElement("heading", double: wp.heading)
                    builder.optionalElement("heartrate", double: wp.heartRate)
                    builder.optionalElement("otu", double: wp.otu)
                    builder.optionalElement("bodytemperature", double: wp.bodyTemperature)
                    builder.optionalElement("batterychargecondition", double: wp.batteryChargeCondition)

                    // Battery voltages
                    for batt in wp.batteryVoltages {
                        var attrs: [(String, String)] = []
                        if let ref = batt.ref { attrs.append(("ref", ref)) }
                        builder.element("batteryvoltage", text: "\(batt.value)", attributes: attrs)
                    }

                    // Scrubber
                    for scrub in wp.scrubberReadings {
                        var attrs: [(String, String)] = []
                        if let ref = scrub.ref { attrs.append(("ref", ref)) }
                        builder.element("scrubber", text: "\(scrub.value)", attributes: attrs)
                    }

                    // Alarms
                    for alarm in wp.alarms {
                        var attrs: [(String, String)] = []
                        if let level = alarm.level { attrs.append(("level", "\(level)")) }
                        if let tankRef = alarm.tankRef { attrs.append(("tankref", tankRef)) }
                        let text = alarm.message ?? alarm.type?.rawValue ?? ""
                        builder.element("alarm", text: text, attributes: attrs)
                    }

                    builder.optionalElement("remainingbottomtime", double: wp.remainingBottomTime)
                    builder.optionalElement("remainingo2time", double: wp.remainingO2Time)
                    if wp.setMarker == true { builder.emptyElement("setmarker") }
                }
            }
        }
    }

    private func writeAfterDive(_ dive: UDDFDive, builder: XMLBuilder) {
        builder.element("informationafterdive") {
            builder.optionalElement("greatestdepth", double: dive.greatestDepth)
            builder.optionalElement("averagedepth", double: dive.averageDepth)
            builder.optionalElement("diveduration", double: dive.duration)
            builder.optionalElement("lowesttemperature", double: dive.lowestTemperature)
            builder.optionalElement("highestpo2", double: dive.highestPO2)
            builder.optionalElement("visibility", double: dive.visibility)
            builder.optionalElement("desaturationtime", double: dive.desaturationTime)
            builder.optionalElement("noflighttime", double: dive.noFlightTime)
            builder.optionalElement("pressuredrop", double: dive.pressureDrop)

            if let current = dive.current { builder.element("current", text: current.rawValue) }
            if let comfort = dive.thermalComfort { builder.element("thermalcomfort", text: comfort.rawValue) }
            if let workload = dive.workload { builder.element("workload", text: workload.rawValue) }
            if let program = dive.program { builder.element("program", text: program.rawValue) }

            if let r = dive.rating {
                builder.element("rating") { builder.element("ratingvalue", text: "\(r)") }
            }

            // Equipment used
            if !dive.equipmentUsedRefs.isEmpty || dive.leadQuantity != nil {
                builder.element("equipmentused") {
                    builder.optionalElement("leadquantity", double: dive.leadQuantity)
                    for ref in dive.equipmentUsedRefs {
                        builder.emptyElement("link", attributes: [("ref", ref)])
                    }
                }
            }

            builder.optionalElement("surfaceintervalafterdive", double: dive.surfaceIntervalAfterDive)

            // Observations
            if let obs = dive.observations {
                builder.element("observations") { writeNotes(obs, builder: builder) }
            }

            // Symptoms
            if let sym = dive.symptoms {
                builder.element("anysymptoms") { writeNotes(sym, builder: builder) }
            }

            writeNotes(dive.notes, builder: builder)
        }
    }

    // MARK: - Notes

    private func writeNotes(_ text: String?, builder: XMLBuilder) {
        guard let text, !text.isEmpty else { return }
        let paragraphs = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        builder.element("notes") {
            for para in paragraphs {
                builder.element("para", text: para)
            }
        }
    }

    // MARK: - Overflow

    private func writeOverflow(_ overflow: [UDDFOverflowEntry]?, builder: XMLBuilder) {
        guard let overflow else { return }
        for entry in overflow {
            builder.rawXML(entry.xml)
        }
    }
}
