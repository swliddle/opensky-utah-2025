//
//  AircraftStateCell.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import SwiftUI

// View to represent an aircraft in the list of aircraft.
struct AircraftStateCell: View {
    let aircraftState: AircraftState

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(aircraftState.flight)
                    .font(.headline)
                Text(
                    "\(aircraftState.altitude), \(aircraftState.speed), \(aircraftState.ascentRate)"
                )
                .font(.subheadline)
            }
            Spacer()
            Image(systemName: aircraftState.status.systemImageName)
                .imageScale(.large)
                .foregroundStyle(.tint)
                .rotationEffect(.degrees(iconRotation))
        }
    }

    // We want to display the icon of an aircraft in flight as rotated to
    // its true heading, but the other icons should be rotated in a fixed
    // position.
    private var iconRotation: Double {
        switch aircraftState.status {
            case .onGround:
                Heading.north
            case .ascending, .descending:
                Heading.notRotated
            case .standard:
                aircraftState.heading
        }
    }

    // MARK: - Constants

    private struct Heading {
        static let north = 270.0
        static let notRotated = 0.0
    }
}

#Preview {
    List {
        AircraftStateCell(aircraftState: AircraftState(icao24: "DAL1464", velocity: 237.5, verticalRate: 1, geoAltitude: 10668))
        AircraftStateCell(aircraftState: AircraftState(icao24: "UAL1693", velocity: 0, verticalRate: 0, geoAltitude: 4500))
    }
}
