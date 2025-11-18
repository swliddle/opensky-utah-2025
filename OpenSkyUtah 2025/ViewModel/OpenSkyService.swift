//
//  OpenSkyService.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import SwiftUI

@MainActor
@Observable class OpenSkyService {

    // MARK: - Properties

    private var aircraftStates: [AircraftState] = []

    // MARK: - Model access

    var locatedAircraftStates: [AircraftState] {
        aircraftStates.filter { $0.latitude != nil && $0.longitude != nil }
    }

    // MARK: - User intents
    func loadSampleData() {
        Task {
            await loadSampleDataAsync()
        }
    }

    func loadSampleDataAsync() async {
        // Load sample data without touching the network
        guard let url = Bundle.main.url(forResource: "SampleOpenSkyData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        await parseAndUpdateStates(from: data)
    }

    func refreshStatus() {
        Task {
            do {
                try await refreshStatusAsync()
            } catch {
                // TODO: handle error as needed (log or expose state)
            }
        }
    }

    func refreshStatusAsync() async throws {
        // Load Utah airplanes from the network API
        guard let url = Utah.openSkyUrl else { return }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        await parseAndUpdateStates(from: data)
    }

    func toggleDetailVisibility(for aircraftState: AircraftState) {
        // Toggle the visibility of this aircraft's detail box (on our map)
        if let selectedIndex = aircraftStates.firstIndex(matching: aircraftState) {
            aircraftStates[selectedIndex].detailsVisible.toggle()
        }
    }

    // MARK: - Private helpers

    private func transferPriorVisibility(from previousStates: [AircraftState]) {
        previousStates.forEach { previousState in
            if previousState.detailsVisible {
                if let selectedIndex = aircraftStates.firstIndex(matching: previousState) {
                    aircraftStates[selectedIndex].detailsVisible = previousState.detailsVisible
                }
            }
        }
    }

    private func parseAndUpdateStates(from data: Data) async {
        // Parse JSON off-main to avoid blocking UI
        let parsed: [AircraftState] = await Task.detached(priority: .userInitiated) {
            guard let response = try? JSONDecoder().decode(OpenSkyResponse.self, from: data),
                  let states = response.states else {
                return []
            }
            return states
        }.value

        let previousStates = aircraftStates
        aircraftStates = parsed
        transferPriorVisibility(from: previousStates)
    }
}
