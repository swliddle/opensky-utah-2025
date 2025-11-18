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
        let rawStates: [[Any]] = await Task.detached(priority: .userInitiated) { () -> [[Any]] in
            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let states = json[await Key.statesKey] as? [[Any]]
            else {
                return []
            }
            return states
        }.value

        // Map to model types on the main actor to respect actor isolation of the initializer
        let parsed: [AircraftState] = await MainActor.run {
            rawStates.map { AircraftState(from: $0) }
        }

        let previousStates = aircraftStates
        aircraftStates = parsed
        transferPriorVisibility(from: previousStates)
    }
}

struct Key {
    static let statesKey = "states"
}
