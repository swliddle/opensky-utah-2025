//
//  CacheManager.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation

/// Actor that manages caching of OpenSky network responses to disk
actor CacheManager {

    // MARK: - Types

    struct CachedData: Codable {
        let timestamp: Date
        let data: Data
    }

    // MARK: - Properties

    private let cacheFileName = "opensky-cache.json"

    private var cacheFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFileName)
    }

    // MARK: - Public methods

    /// Save OpenSky response data to cache
    /// - Parameter data: The raw JSON data from the OpenSky API
    func save(_ data: Data) async throws {
        let cachedData = CachedData(timestamp: Date(), data: data)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(cachedData)
        try encodedData.write(to: cacheFileURL, options: .atomic)
        print("✅ Cache saved: \(cacheFileURL.path)")
    }

    /// Load cached OpenSky response data
    /// - Returns: Tuple of (data, timestamp) if cache exists, nil otherwise
    func load() async -> (data: Data, timestamp: Date)? {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            print("⚠️ No cache file found")
            return nil
        }

        do {
            let fileData = try Data(contentsOf: cacheFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cachedData = try decoder.decode(CachedData.self, from: fileData)
            print("✅ Cache loaded: \(cachedData.timestamp)")
            return (cachedData.data, cachedData.timestamp)
        } catch {
            print("❌ Failed to load cache: \(error.localizedDescription)")
            return nil
        }
    }

    /// Clear the cache file
    func clear() async throws {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: cacheFileURL)
        print("🗑️ Cache cleared")
    }
}
