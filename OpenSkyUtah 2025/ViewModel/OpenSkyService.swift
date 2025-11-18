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

    // Dependencies
    private let cacheManager = CacheManager()
    private let networkMonitor = NetworkMonitor()

    // Task tracking for cancellation and deduplication
    private var refreshTask: Task<Void, Never>?
    private var autoRefreshTask: Task<Void, Never>?

    // MARK: - Model access

    var locatedAircraftStates: [AircraftState] {
        aircraftStates.filter { $0.latitude != nil && $0.longitude != nil }
    }

    // MARK: - Public methods

    /// Load initial data on app launch - cache first, then sample data fallback
    func loadInitialData() async {
        // First, try to load from cache
        if let (data, timestamp) = await cacheManager.load() {
            await parseAndUpdateStates(from: data)
            lastFetchDate = timestamp
            dataSource = .cache
            print("📦 Loaded cached data from \(timestamp)")
        } else {
            // No cache available, load sample data
            await loadSampleDataAsync()
        }

        // Check network status
        isOffline = !(await networkMonitor.checkConnection())

        // If online, fetch fresh data
        if !isOffline {
            await refreshFromNetwork()
        }
    }

    /// Start auto-refresh timer (30 seconds)
    func startAutoRefresh() {
        // Cancel any existing auto-refresh
        autoRefreshTask?.cancel()

        autoRefreshTask = Task {
            while !Task.isCancelled {
                // Wait 30 seconds
                try? await Task.sleep(for: .seconds(30))

                guard !Task.isCancelled else { break }

                // Only refresh if online
                let connected = await networkMonitor.checkConnection()
                isOffline = !connected

                if connected {
                    await refreshFromNetwork()
                }
            }
        }
    }

    /// Stop auto-refresh timer
    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    /// Manual refresh triggered by user (pull-to-refresh)
    func refresh() async {
        // Check network status
        let connected = await networkMonitor.checkConnection()
        isOffline = !connected

        if connected {
            await refreshFromNetwork()
        } else {
            errorMessage = "No network connection available"
        }
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
        // Cancel any in-flight refresh to avoid duplication
        refreshTask?.cancel()

        refreshTask = Task {
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

                // Cache the successful response
                try? await cacheManager.save(data)

                // Update metadata
                lastFetchDate = Date()
                dataSource = .network
                isLoading = false

                print("🌐 Fetched live data from network")

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

        await refreshTask?.value
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
