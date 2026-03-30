import Foundation

// MARK: - Dive

/// A single dive from `<profiledata><repetitiongroup><dive>`.
public struct UDDFDive: Codable, Sendable {
    public let id: String?
    public let repetitionGroupId: String?

    // MARK: informationbeforedive

    public let number: Int?
    public let divenumberOfDay: Int?
    public let internalDiveNumber: Int?
    public let datetime: String?
    public let altitude: Double?                    // meters
    public let surfacePressure: Double?             // Pascals
    public let airTemperature: Double?              // Kelvin
    public let surfaceInterval: Double?             // seconds
    public let surfaceIntervalIsInfinity: Bool?     // first dive of series
    public let apparatus: UDDFApparatus?
    public let platform: UDDFPlatform?
    public let purpose: UDDFPurpose?
    public let stateOfRest: UDDFStateOfRest?
    public let noSuit: Bool?                        // <nosuit/> empty element
    public let price: Double?                       // dive cost
    public let siteRef: String?
    public let buddyRefs: [String]
    public let equipmentRefs: [String]
    public let decoModelRef: String?

    // MARK: informationafterdive

    public let greatestDepth: Double?               // meters
    public let averageDepth: Double?                // meters
    public let duration: Double?                    // seconds
    public let lowestTemperature: Double?           // Kelvin
    public let highestPO2: Double?                  // Pascals
    public let visibility: Double?                  // meters
    public let desaturationTime: Double?            // seconds
    public let noFlightTime: Double?                // seconds
    public let pressureDrop: Double?                // Pascals
    public let current: UDDFCurrent?
    public let thermalComfort: UDDFThermalComfort?
    public let workload: UDDFWorkload?
    public let program: UDDFProgram?
    public let rating: Double?
    public let equipmentUsedRefs: [String]
    public let leadQuantity: Double?                // kg — from <equipmentused><leadquantity>
    public let surfaceIntervalAfterDive: Double?    // seconds
    public let observations: String?                // marine life from <observations>
    public let symptoms: String?                    // DCS symptoms from <anysymptoms>
    public let notes: String?

    // MARK: tankdata + samples

    public let tanks: [UDDFTankData]
    public let waypoints: [UDDFWaypoint]
    public let overflow: [UDDFOverflowEntry]?

    public init(
        id: String? = nil, repetitionGroupId: String? = nil,
        // before
        number: Int? = nil, divenumberOfDay: Int? = nil,
        internalDiveNumber: Int? = nil, datetime: String? = nil,
        altitude: Double? = nil, surfacePressure: Double? = nil,
        airTemperature: Double? = nil, surfaceInterval: Double? = nil,
        surfaceIntervalIsInfinity: Bool? = nil,
        apparatus: UDDFApparatus? = nil, platform: UDDFPlatform? = nil,
        purpose: UDDFPurpose? = nil, stateOfRest: UDDFStateOfRest? = nil,
        noSuit: Bool? = nil, price: Double? = nil,
        siteRef: String? = nil, buddyRefs: [String] = [],
        equipmentRefs: [String] = [], decoModelRef: String? = nil,
        // after
        greatestDepth: Double? = nil, averageDepth: Double? = nil,
        duration: Double? = nil, lowestTemperature: Double? = nil,
        highestPO2: Double? = nil, visibility: Double? = nil,
        desaturationTime: Double? = nil, noFlightTime: Double? = nil,
        pressureDrop: Double? = nil, current: UDDFCurrent? = nil,
        thermalComfort: UDDFThermalComfort? = nil, workload: UDDFWorkload? = nil,
        program: UDDFProgram? = nil, rating: Double? = nil,
        equipmentUsedRefs: [String] = [], leadQuantity: Double? = nil,
        surfaceIntervalAfterDive: Double? = nil,
        observations: String? = nil, symptoms: String? = nil,
        notes: String? = nil,
        // data
        tanks: [UDDFTankData] = [], waypoints: [UDDFWaypoint] = [],
        overflow: [UDDFOverflowEntry]? = nil
    ) {
        self.id = id
        self.repetitionGroupId = repetitionGroupId
        self.number = number
        self.divenumberOfDay = divenumberOfDay
        self.internalDiveNumber = internalDiveNumber
        self.datetime = datetime
        self.altitude = altitude
        self.surfacePressure = surfacePressure
        self.airTemperature = airTemperature
        self.surfaceInterval = surfaceInterval
        self.surfaceIntervalIsInfinity = surfaceIntervalIsInfinity
        self.apparatus = apparatus
        self.platform = platform
        self.purpose = purpose
        self.stateOfRest = stateOfRest
        self.noSuit = noSuit
        self.price = price
        self.siteRef = siteRef
        self.buddyRefs = buddyRefs
        self.equipmentRefs = equipmentRefs
        self.decoModelRef = decoModelRef
        self.greatestDepth = greatestDepth
        self.averageDepth = averageDepth
        self.duration = duration
        self.lowestTemperature = lowestTemperature
        self.highestPO2 = highestPO2
        self.visibility = visibility
        self.desaturationTime = desaturationTime
        self.noFlightTime = noFlightTime
        self.pressureDrop = pressureDrop
        self.current = current
        self.thermalComfort = thermalComfort
        self.workload = workload
        self.program = program
        self.rating = rating
        self.equipmentUsedRefs = equipmentUsedRefs
        self.leadQuantity = leadQuantity
        self.surfaceIntervalAfterDive = surfaceIntervalAfterDive
        self.observations = observations
        self.symptoms = symptoms
        self.notes = notes
        self.tanks = tanks
        self.waypoints = waypoints
        self.overflow = overflow
    }
}

// MARK: - Tank Data

/// Tank data from `<tankdata>` element (child of `<dive>`).
public struct UDDFTankData: Codable, Sendable {
    public let id: String?
    public let mixRef: String?
    public let tankRef: String?
    public let pressureBegin: Double?               // Pascals
    public let pressureEnd: Double?                 // Pascals
    public let volume: Double?                      // cubic meters
    public let breathingConsumptionVolume: Double?   // m³/s

    public init(
        id: String? = nil, mixRef: String? = nil, tankRef: String? = nil,
        pressureBegin: Double? = nil, pressureEnd: Double? = nil,
        volume: Double? = nil, breathingConsumptionVolume: Double? = nil
    ) {
        self.id = id
        self.mixRef = mixRef
        self.tankRef = tankRef
        self.pressureBegin = pressureBegin
        self.pressureEnd = pressureEnd
        self.volume = volume
        self.breathingConsumptionVolume = breathingConsumptionVolume
    }
}
