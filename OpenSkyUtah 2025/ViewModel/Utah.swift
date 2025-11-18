//
//  Utah.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation
import MapKit

struct Utah {

    // MARK: - Public constants

    static let latitudeMax = 42.0
    static let latitudeMin = 37.0
    static let longitudeMax = -109.0
    static let longitudeMin = -114.0

    // MARK: - Private constants

    private static let baseApiUrl = "https://opensky-network.org/api"
    private static let getStatesApi = "/states/all"
    private static let margin = 1.05

    // MARK: - Private computed properties

    private static var center: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitudeMin + (latitudeMax - latitudeMin) / 2,
            longitude: longitudeMin + (longitudeMax - longitudeMin) / 2
        )
    }

    private static var span: MKCoordinateSpan {
        MKCoordinateSpan(
            latitudeDelta: abs(latitudeMax - latitudeMin) * margin,
            longitudeDelta: abs(longitudeMax - longitudeMin) * margin
        )
    }

    private static var urlString: String {
        """
        \(baseApiUrl)\
        \(getStatesApi)?\
        lamin=\(latitudeMin)&\
        lamax=\(latitudeMax)&\
        lomin=\(longitudeMin)&\
        lomax=\(longitudeMax)
        """
    }

    // MARK: - Public properties

    static var region: MKCoordinateRegion {
        MKCoordinateRegion(center: center, span: span)
    }

    static var openSkyUrl: URL? = URL(string: urlString)
}
