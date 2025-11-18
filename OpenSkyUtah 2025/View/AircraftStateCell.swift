//
//  AircraftStateCell.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import SwiftUI

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
