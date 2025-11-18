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
            // Load initial data and start auto-refresh
            await openSkyService.loadInitialData()
            openSkyService.startAutoRefresh()

            // Keep task alive and cleanup on cancellation
            await withTaskCancellationHandler {
                // Keep the task alive until cancelled, sleeping in long chunks
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60 * 60))
                }
            } onCancel: {
                // Stop auto-refresh when view disappears
                Task { @MainActor in
                    openSkyService.stopAutoRefresh()
                }
            }
        }
        .alert("Error", isPresented: .constant(openSkyService.errorMessage != nil)) {
            Button("OK") {
                openSkyService.errorMessage = nil
            }
        } message: {
            if let errorMessage = openSkyService.errorMessage {
                Text(errorMessage)
            }
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    statusView
                }
            }
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

                // Offline banner at top
                if openSkyService.isOffline {
                    VStack {
                        offlineBanner
                        Spacer()
                    }
                }
            }
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    statusView
                }
            }
        }
    }

    private var statusView: some View {
        VStack(spacing: 2) {
            Text(Constants.title)
                .font(.headline)

            HStack(spacing: 4) {
                // Loading indicator
                if openSkyService.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                // Data source indicator
                Text(dataSourceText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Offline indicator
                if openSkyService.isOffline {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
            Text(offlineBannerText)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.red.opacity(0.9))
        .foregroundStyle(.white)
        .cornerRadius(8)
        .padding()
    }

    private var offlineBannerText: String {
        switch openSkyService.dataSource {
        case .cache:
            return "Offline - Showing Cached Data"
        case .sample:
            return "Offline - Showing Sample Data"
        default:
            return "Offline"
        }
    }

    private var dataSourceText: String {
        let source: String
        switch openSkyService.dataSource {
        case .none:
            source = "No data"
        case .sample:
            source = "Sample"
        case .cache:
            source = "Cached"
        case .network:
            source = "Live"
        }

        if let lastFetch = openSkyService.lastFetchDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            let timeAgo = formatter.localizedString(for: lastFetch, relativeTo: Date())
            return "\(source) • \(timeAgo)"
        } else {
            return source
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

