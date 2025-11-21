//
//  AircraftState.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation
import CoreLocation

struct AircraftState: Codable {

    // MARK: - Position source

    enum PositionSource: Int, Codable {
        case adsb = 0
        case asterix = 1
        case mlat = 2
        case flarm = 3
    }

    // MARK: - Properties
    // See https://openskynetwork.github.io/opensky-api/ for documentation of these fields

    var icao24: String
    var callsign: String?
    var originCountry: String
    var timePosition: Int?
    var lastContact: Int
    var longitude: Double?
    var latitude: Double?
    var baroAltitude: Double?
    var onGround: Bool
    var velocity: Double?
    var trueTrack: Double?
    var verticalRate: Double?
    var sensors: [Int]? = []
    var geoAltitude: Double?
    var squawk: String?
    var specialPurposeIndicator: Bool
    var positionSource: PositionSource

    // This additionally indicates whether the aircraft's details are visible
    // on the map.  If false, just the call sign is visible.
    var detailsVisible = false

    // MARK: - Initialization

    // Convenience helper for using in previews
    init(icao24: String, velocity: Double, verticalRate: Double, geoAltitude: Double) {
        self.icao24 = icao24
        self.velocity = velocity
        self.verticalRate = verticalRate
        self.geoAltitude = geoAltitude
        self.originCountry = ""
        lastContact = 0
        onGround = false
        positionSource = .adsb
        specialPurposeIndicator = false
    }

    // Just declaring conformance to Codable is usually enough to synthesize this init
    // method, but because we sometimes want to decode values off the main actor, we
    // need to write the init method and declare it to be nonisolated.  There are also
    // a couple of tweaks we make to what would have been synthesized.
    nonisolated init(from decoder: Decoder) throws {
        // Here, we're telling the decoder that the object we're converting isn't using
        // keys.  OpenSky sends back an array of values for each state object, not a
        // key/value dictionary of properties.  So we should use an unkeyed container.
        var container = try decoder.unkeyedContainer()

        // Decode each field in order according to OpenSky API array format
        icao24 = try container.decode(String.self)
        callsign = try container.decodeIfPresent(String.self)
        originCountry = try container.decode(String.self)
        timePosition = try container.decodeIfPresent(Int.self)
        lastContact = try container.decode(Int.self)
        longitude = try container.decodeIfPresent(Double.self)
        latitude = try container.decodeIfPresent(Double.self)
        baroAltitude = try container.decodeIfPresent(Double.self)
        onGround = try container.decode(Bool.self)
        velocity = try container.decodeIfPresent(Double.self)
        trueTrack = try container.decodeIfPresent(Double.self)
        verticalRate = try container.decodeIfPresent(Double.self)
        sensors = try container.decodeIfPresent([Int].self)
        geoAltitude = try container.decodeIfPresent(Double.self)
        squawk = try container.decodeIfPresent(String.self)
        specialPurposeIndicator = try container.decode(Bool.self)

        // The synthesized init would not do the following, which we do to provide a
        // default value of .adsb for positionSource.  This might be overkill.
        let positionSourceValue = try container.decode(Int.self)

        positionSource = PositionSource(rawValue: positionSourceValue) ?? .adsb
    }

    // Again, there is a default implementation of encode that is provided when
    // we declare conformance to Codable, but if we write our own version, we can
    // control things like using an unkeyed container.  And importantly, we can
    // allow this function to work in nonisolated contexts.
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        // Encode each field in order according to OpenSky API array format
        try container.encode(icao24)
        try container.encode(callsign)
        try container.encode(originCountry)
        try container.encode(timePosition)
        try container.encode(lastContact)
        try container.encode(longitude)
        try container.encode(latitude)
        try container.encode(baroAltitude)
        try container.encode(onGround)
        try container.encode(velocity)
        try container.encode(trueTrack)
        try container.encode(verticalRate)
        try container.encode(sensors)
        try container.encode(geoAltitude)
        try container.encode(squawk)
        try container.encode(specialPurposeIndicator)
        try container.encode(positionSource.rawValue)
    }

    // MARK: - Computed properties

    // Altitude string, specific for U.S. locale
    var altitude: String {
        String(format: "%.0f ft", (baroAltitude ?? geoAltitude ?? 0) * Conversion.feetPerMeter)
    }

    // Ascent rate string, specific for U.S. locale
    var ascentRate: String {
        String(format: "%.1f ft/s", (verticalRate ?? 0) * Conversion.feetPerMeter)
    }

    // Aircraft's location, converted to non-optional format
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }

    // Flight string, hopefully the call sign, but if needed, an ICAO string
    var flight: String {
        let sign = callsign?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return sign.isEmpty ? "ICAO \(icao24)" : sign
    }

    // Aircraft's heading, adjusted 90 degrees counter-clockwise to match
    // the coordinate system in iOS
    var heading: Double {
        (trueTrack ?? 0) - 90
    }

    var isAscending: Bool {
        verticalRate ?? 0 > 0
    }

    var isDescending: Bool {
        verticalRate ?? 0 < 0
    }

    // Speed string, specific for U.S. locale
    var speed: String {
        String(format: "%.1f mph", (velocity ?? 0) * Conversion.milesPerHourPerMetersPerSecond)
    }

    // Aircraft's status as ascending/descending/on-ground/standard
    var status: AircraftStatus {
        if isAscending {
            .ascending
        } else if isDescending {
            .descending
        } else if onGround {
            .onGround
        } else {
            .standard
        }
    }

    // MARK: - Constants

    // Conversion constants for metric to imperial units
    private struct Conversion {
        static let feetPerMeter = 3.280839895
        static let milesPerHourPerMetersPerSecond = feetPerMeter * 3600 / 5280
    }
}

extension AircraftState: Identifiable {
    // ICAO strings are unique, so we can use them to conform to Identifiable
    var id: String {
        "s\(icao24)"
    }
}
