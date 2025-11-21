//
//  AircraftStatus+Icon.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation

extension AircraftStatus {
    // Icon names to be used on the map (either in the air or on the ground)
    var airborneImageName: String {
        switch self {
            case .onGround:
                "airplane.circle"
            default:
                "airplane"
        }
    }

    // Icon names to be used on the list
    var systemImageName: String {
        switch self {
            case .ascending:
                "airplane.departure"
            case .descending:
                "airplane.arrival"
            case .onGround:
                "airplane.circle"
            case .standard:
                "airplane"
        }
    }
}
