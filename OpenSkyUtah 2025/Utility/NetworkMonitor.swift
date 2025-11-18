//
//  NetworkMonitor.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation
import Network

/// Actor that monitors network connectivity status
actor NetworkMonitor {

    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private(set) var isConnected = false

    // MARK: - Initialization

    init() {
        startMonitoring()
    }

    // MARK: - Public methods

    /// Check current connection status
    func checkConnection() -> Bool {
        isConnected
    }

    // MARK: - Private methods

    nonisolated private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { [weak self] in
                await self?.updateConnectionStatus(path.status == .satisfied)
            }
        }

        monitor.start(queue: queue)
    }

    private func updateConnectionStatus(_ connected: Bool) {
        let wasConnected = isConnected

        isConnected = connected

        if wasConnected != connected {
            print(connected ? "🌐 Network connected" : "📡 Network disconnected")
        }
    }

    deinit {
        monitor.cancel()
    }
}
