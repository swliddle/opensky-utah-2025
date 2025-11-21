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
    private var lastUpdate = Date()
    
    private var cacheFileUrl: URL {
        URL.documentsDirectory.appending(path: "opensky_cache.json")
    }

    // MARK: - Model access

    var locatedAircraftStates: [AircraftState] {
        aircraftStates.filter { $0.latitude != nil && $0.longitude != nil }
    }

    // MARK: - Public methods

    // Load initial data on app launch - cache first, then sample data fallback
    func loadInitialData() async {
        if await !loadFromCache() {
            await loadSampleData()
        }
        
        startAutoRefresh()
    }

    // Manual refresh triggered by user (pull-to-refresh)
    func refresh() async {
        await refreshFromNetwork()
    }

    // Toggle detail visibility for an aircraft on the map
    func toggleDetailVisibility(for aircraftState: AircraftState) {
        if let selectedIndex = aircraftStates.firstIndex(matching: aircraftState) {
            aircraftStates[selectedIndex].detailsVisible.toggle()
        }
    }

    // MARK: - Private methods

    // Load sample data from bundle
    private func loadSampleData() async {
        guard let url = Bundle.main.url(forResource: "SampleOpenSkyData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }
        await parseAndUpdateStates(from: data)
    }
    
    private func loadFromCache() async -> Bool {
        guard let data = try? Data(contentsOf: cacheFileUrl) else {
            return false
        }
        
        await parseAndUpdateStates(from: data)
        
        return true
    }

    // Parse JSON data and update aircraft states
    private func parseAndUpdateStates(from data: Data) async {
        do {
            let states = try await parse(data: data)

            guard !states.isEmpty else {
                return
            }

            let previousStates = aircraftStates

            aircraftStates = states
            transferPriorVisibility(from: previousStates)
        } catch {
            print("JSON parsing failed: \(error)")
        }
    }

    // Helper to parse data off the main actor
    nonisolated private func parse(data: Data) async throws -> [AircraftState] {
        let decoder = JSONDecoder()
        let response = try decoder.decode(OpenSkyResponse.self, from: data)

        return response.states ?? []
    }
    
    private func refreshFromNetwork() async {
        guard !Task.isCancelled else {
            return
        }

        guard let url = Utah.openSkyUrl else {
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard !Task.isCancelled else {
                return
            }

            if let http = response as? HTTPURLResponse,
               !(200...299).contains(http.statusCode) {
                return
            }

            await parseAndUpdateStates(from: data)
            saveToCache(data: data)
        } catch {
            // Ignore failure, just don't replace the data
        }
    }

    private func saveToCache(data: Data) {
        try? data.write(to: cacheFileUrl)
    }

    private func startAutoRefresh() {
        Task {
            while !Task.isCancelled {
                await refreshFromNetwork()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    // Transfer detailsVisible state from previous data to new data
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
