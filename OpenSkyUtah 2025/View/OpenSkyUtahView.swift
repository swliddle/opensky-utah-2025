//
//  OpenSkyUtahView.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import SwiftUI
import MapKit

struct OpenSkyUtahView: View {

    private enum Tabs {
        case list
        case map
    }

    let openSkyService: OpenSkyService

    @State private var selectedTab = Tabs.map

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Aircraft", systemImage: "list.triangle", value: .list) {
                aircraftList
            }
            Tab("Map", systemImage: "map", value: .map) {
                aircraftMap
            }
        }
        .task {
            await openSkyService.loadInitialData()
        }
    }

    private var aircraftList: some View {
        NavigationStack {
            List {
                ForEach(openSkyService.locatedAircraftStates) { aircraftState in
                    AircraftStateCell(aircraftState: aircraftState)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await openSkyService.refresh()
            }
            .navigationTitle(Constants.title)
        }
    }

    private var aircraftMap: some View {
        NavigationStack {
            ZStack {
                Map(initialPosition: .region(Utah.region)) {
                    ForEach(openSkyService.locatedAircraftStates) { aircraftState in
                        Annotation(
                            labelText(for: aircraftState),
                            coordinate: aircraftState.coordinate
                        ) {
                            Image(systemName: aircraftState.status.airborneImageName)
                                .imageScale(.large)
                                .foregroundStyle(.tint)
                                .rotationEffect(.degrees(aircraftState.heading))
                                .onTapGesture {
                                    withAnimation {
                                        openSkyService
                                            .toggleDetailVisibility(for: aircraftState)
                                    }
                                }
                        }
                    }
                }
                .mapStyle(.standard)
                .mapControlVisibility(.visible)
            }
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func labelText(for aircraftState: AircraftState) -> String {
        if aircraftState.detailsVisible {
            """
            \(aircraftState.flight)
            \(aircraftState.altitude)
            \(aircraftState.speed)
            \(aircraftState.ascentRate)
            """
        } else {
            aircraftState.flight
        }
    }

    // MARK: - Constants

    private struct Constants {
        static let title = "OpenSky Utah"
    }
}

#Preview {
    OpenSkyUtahView(openSkyService: OpenSkyService())
}
