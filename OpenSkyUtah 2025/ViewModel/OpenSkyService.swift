//
//  OpenSkyService.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import SwiftUI

@MainActor
@Observable class OpenSkyService {

    // MARK: - Types

    enum DataSource {
        case none
        case sample
        case cache
        case network
    }

    // MARK: - Properties

    private var aircraftStates: [AircraftState] = []

    // State tracking
    var isLoading = false
    var isOffline = false
    var lastFetchDate: Date?
    var errorMessage: String?
    var dataSource: DataSource = .none

    // MARK: - Model access

    var locatedAircraftStates: [AircraftState] {
        aircraftStates.filter { $0.latitude != nil && $0.longitude != nil }
    }

    // MARK: - Public methods

    /// Load initial data on app launch - cache first, then sample data fallback
    func loadInitialData() async {
        await loadSampleDataAsync()
    }

    /// Manual refresh triggered by user (pull-to-refresh)
    func refresh() async {
        await refreshFromNetwork()
    }

    /// Toggle detail visibility for an aircraft on the map
    func toggleDetailVisibility(for aircraftState: AircraftState) {
        if let selectedIndex = aircraftStates.firstIndex(matching: aircraftState) {
            aircraftStates[selectedIndex].detailsVisible.toggle()
        }
    }

    // MARK: - Private methods

    /// Load sample data from bundle
    private func loadSampleDataAsync() async {
        guard let url = Bundle.main.url(forResource: "SampleOpenSkyData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            errorMessage = "Failed to load sample data"
            return
        }
        await parseAndUpdateStates(from: data)
        dataSource = .sample
        lastFetchDate = nil
        print("📝 Loaded sample data")
    }

    /// Fetch fresh data from network and cache it
    private func refreshFromNetwork() async {
        Task {
            guard !Task.isCancelled else { return }

            isLoading = true
            errorMessage = nil

            do {
                guard let url = Utah.openSkyUrl else {
                    errorMessage = "Invalid API URL"
                    isLoading = false
                    return
                }

                let (data, response) = try await URLSession.shared.data(from: url)

                guard !Task.isCancelled else {
                    isLoading = false
                    return
                }

                // Validate HTTP response
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    errorMessage = "Server error: HTTP \(http.statusCode)"
                    isLoading = false
                    return
                }

                // Parse and update states
                await parseAndUpdateStates(from: data)
            } catch {
                guard !Task.isCancelled else {
                    isLoading = false
                    return
                }

                errorMessage = "Network error: \(error.localizedDescription)"
                isLoading = false
                print("❌ Network fetch failed: \(error)")
            }
        }
    }

    /// Parse JSON data and update aircraft states
    private func parseAndUpdateStates(from data: Data) async {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(OpenSkyResponse.self, from: data)

            guard let states = response.states, !states.isEmpty else {
                errorMessage = "No aircraft data available"
                return
            }

            let previousStates = aircraftStates
            aircraftStates = states
            transferPriorVisibility(from: previousStates)
            errorMessage = nil

        } catch {
            errorMessage = "Failed to parse data: \(error.localizedDescription)"
            print("❌ JSON parsing failed: \(error)")
        }
    }

    /// Transfer detailsVisible state from previous data to new data
    private func transferPriorVisibility(from previousStates: [AircraftState]) {
        previousStates.forEach { previousState in
            if previousState.detailsVisible {
                if let selectedIndex = aircraftStates.firstIndex(matching: previousState) {
                    aircraftStates[selectedIndex].detailsVisible = previousState.detailsVisible
                }
            }
        }
    }
}
