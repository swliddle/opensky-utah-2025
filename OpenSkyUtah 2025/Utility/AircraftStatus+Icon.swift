//
//  AircraftStatus+Icon.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation

import Foundation

extension AircraftStatus {
    var airborneImageName: String {
        switch self {
            case .onGround:
                "airplane.circle"
            default:
                "airplane"
        }
    }

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
