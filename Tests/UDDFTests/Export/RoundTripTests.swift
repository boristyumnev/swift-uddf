import Foundation
import Testing
@testable import UDDF

struct RoundTripTests {

    func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name, withExtension: "uddf")!
        return try Data(contentsOf: url)
    }

    func roundTrip(_ name: String) throws -> (original: UDDFDocument, roundTripped: UDDFDocument) {
        let data = try loadFixture(name)
        let original = try UDDFParser.parse(data: data).document
        let exported = try UDDFExporter.export(document: original)
        let roundTripped = try UDDFParser.parse(data: exported).document
        return (original, roundTripped)
    }

    // MARK: - Minimal Valid Golden Test

    @Test func minimal_version() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        #expect(rt.version == orig.version)
    }

    @Test func minimal_generator() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        #expect(rt.generator.name == orig.generator.name)
        #expect(rt.generator.version == orig.generator.version)
    }

    @Test func minimal_mixes() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        #expect(rt.mixes.count == orig.mixes.count)
        for (key, mix) in orig.mixes {
            let rtMix = rt.mixes[key]
            #expect(rtMix != nil, "Missing mix: \(key)")
            #expect(rtMix?.o2 == mix.o2)
            #expect(rtMix?.he == mix.he)
            #expect(rtMix?.name == mix.name)
        }
    }

    @Test func minimal_sites() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        #expect(rt.sites.count == orig.sites.count)
        for (key, site) in orig.sites {
            let rtSite = rt.sites[key]
            #expect(rtSite != nil, "Missing site: \(key)")
            #expect(rtSite?.name == site.name)
            #expect(rtSite?.latitude == site.latitude)
            #expect(rtSite?.longitude == site.longitude)
        }
    }

    @Test func minimal_diveCount() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        #expect(rt.dives.count == orig.dives.count)
    }

    @Test func minimal_diveMetadata() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        let o = orig.dives[0]
        let r = rt.dives[0]
        #expect(r.id == o.id)
        #expect(r.number == o.number)
        #expect(r.datetime == o.datetime)
        #expect(r.greatestDepth == o.greatestDepth)
        #expect(r.averageDepth == o.averageDepth)
        #expect(r.duration == o.duration)
        #expect(r.surfacePressure == o.surfacePressure)
    }

    @Test func minimal_waypointCount() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        #expect(rt.dives[0].waypoints.count == orig.dives[0].waypoints.count)
    }

    @Test func minimal_waypointValues() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        for (i, oWp) in orig.dives[0].waypoints.enumerated() {
            let rWp = rt.dives[0].waypoints[i]
            #expect(rWp.time == oWp.time, "Waypoint \(i) time mismatch")
            #expect(rWp.depth == oWp.depth, "Waypoint \(i) depth mismatch")
            #expect(rWp.temperature == oWp.temperature, "Waypoint \(i) temp mismatch")
            #expect(rWp.switchMixRef == oWp.switchMixRef, "Waypoint \(i) mixRef mismatch")
            #expect(rWp.diveMode == oWp.diveMode, "Waypoint \(i) mode mismatch")
        }
    }

    @Test func minimal_tankData() throws {
        let (orig, rt) = try roundTrip("minimal-valid")
        #expect(rt.dives[0].tanks.count == orig.dives[0].tanks.count)
        if let oTank = orig.dives[0].tanks.first, let rTank = rt.dives[0].tanks.first {
            #expect(rTank.pressureBegin == oTank.pressureBegin)
            #expect(rTank.pressureEnd == oTank.pressureEnd)
            #expect(rTank.mixRef == oTank.mixRef)
        }
    }

    // MARK: - Real File Round-Trips

    @Test func allFixtures_roundTripWithoutError() throws {
        let fixtures = ["minimal-valid", "dive31", "dive68", "dive105",
                        "subsurface-test42", "apd-inspiration-ccr", "divinglog6-mk3i"]
        for name in fixtures {
            let data = try loadFixture(name)
            let result = try UDDFParser.parse(data: data)
            let exported = try UDDFExporter.export(document: result.document)
            let reparse = try UDDFParser.parse(data: exported)
            #expect(reparse.document.dives.count == result.document.dives.count,
                    "Dive count mismatch for \(name)")
        }
    }

    @Test func dive31_roundTrip_diveMetadata() throws {
        let (orig, rt) = try roundTrip("dive31")
        let o = orig.dives[0]
        let r = rt.dives[0]
        #expect(r.number == o.number)
        #expect(r.datetime == o.datetime)
        #expect(r.greatestDepth == o.greatestDepth)
        #expect(r.duration == o.duration)
    }

    @Test func dive31_roundTrip_waypointCount() throws {
        let (orig, rt) = try roundTrip("dive31")
        #expect(rt.dives[0].waypoints.count == orig.dives[0].waypoints.count)
    }

    @Test func dive105_roundTrip_mixes() throws {
        let (orig, rt) = try roundTrip("dive105")
        #expect(rt.mixes.count == orig.mixes.count)
        for (key, mix) in orig.mixes {
            #expect(rt.mixes[key]?.o2 == mix.o2, "O2 mismatch for \(key)")
            #expect(rt.mixes[key]?.he == mix.he, "He mismatch for \(key)")
        }
    }

    @Test func subsurface_roundTrip_site() throws {
        let (orig, rt) = try roundTrip("subsurface-test42")
        for (key, site) in orig.sites {
            let rtSite = rt.sites[key]
            #expect(rtSite?.name == site.name)
            #expect(rtSite?.latitude == site.latitude)
            #expect(rtSite?.longitude == site.longitude)
        }
    }
}
