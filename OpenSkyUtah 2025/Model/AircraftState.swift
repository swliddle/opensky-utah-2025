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

    var detailsVisible = false

    // MARK: - Initialization

    nonisolated init(from decoder: Decoder) throws {
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

        let positionSourceValue = try container.decode(Int.self)
        positionSource = PositionSource(rawValue: positionSourceValue) ?? .adsb

        detailsVisible = false
    }

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

    var altitude: String {
        String(format: "%.0f ft", (baroAltitude ?? geoAltitude ?? 0) * Conversion.feetPerMeter)
    }

    var ascentRate: String {
        String(format: "%.1f ft/s", (verticalRate ?? 0) * Conversion.feetPerMeter)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude ?? 0, longitude: longitude ?? 0)
    }

    var flight: String {
        let sign = callsign?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return sign.isEmpty ? "ICAO \(icao24)" : sign
    }

    var heading: Double {
        (trueTrack ?? 0) - 90
    }

    var isAscending: Bool {
        verticalRate ?? 0 > 0
    }

    var isDescending: Bool {
        verticalRate ?? 0 < 0
    }

    var speed: String {
        String(format: "%.1f mph", (velocity ?? 0) * Conversion.milesPerHourPerMetersPerSecond)
    }

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

    private struct Conversion {
        static let feetPerMeter = 3.280839895
        static let milesPerHourPerMetersPerSecond = feetPerMeter * 3600 / 5280
    }
}

extension AircraftState: Identifiable {
    var id: String {
        "s\(icao24)"
    }
}
