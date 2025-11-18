//
//  AircraftState.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation
import CoreLocation

struct AircraftState {

    // MARK: - Position source

    enum PositionSource: Int {
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

    init(from element: [Any]) {
        icao24 = AircraftState.string(for: element[0])
        callsign = element[1] as? String
        originCountry = AircraftState.string(for: element[2])
        timePosition = element[3] as? Int
        lastContact = AircraftState.int(for: element[4])
        longitude = element[5] as? Double
        latitude = element[6] as? Double
        baroAltitude = element[7] as? Double
        onGround = AircraftState.boolean(for: element[8])
        velocity = element[9] as? Double
        trueTrack = element[10] as? Double
        verticalRate = element[11] as? Double
        geoAltitude = element[13] as? Double
        squawk = element[14] as? String
        specialPurposeIndicator = AircraftState.boolean(for: element[15])
        positionSource = PositionSource(rawValue: AircraftState.int(for: element[16])) ?? .adsb
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

    // MARK: - Helpers

    private static func boolean(for item: Any) -> Bool {
        if let value = item as? Bool {
            return value
        }

        fatalError("Unexpected conversion to boolean failed")
    }

    private static func double(for item: Any) -> Double {
        if let value = item as? Double {
            return value
        }

        fatalError("Unexpected conversion to double failed")
    }

    private static func int(for item: Any) -> Int {
        if let value = item as? Int {
            return value
        }

        fatalError("Unexpected conversion to int failed")
    }

    private static func string(for item: Any) -> String {
        if let value = item as? String {
            return value
        }

        fatalError("Unexpected conversion to string failed")
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
