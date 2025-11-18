//
//  OpenSkyResponse.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation

struct OpenSkyResponse {
    let time: Int?
    let states: [AircraftState]?

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decodeIfPresent(Int.self, forKey: .time)
        states = try container.decodeIfPresent([AircraftState].self, forKey: .states)
    }

    private enum CodingKeys: String, CodingKey {
        case time
        case states
    }
}

extension OpenSkyResponse: Decodable {}
