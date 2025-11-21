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
}

// We could simply declare OpenSkyResponse to be Codable, and that will
// synthesize init and encode methods.  But because we're wanting to control
// isolation mode, we explicitly write out the init ourselves here and use
// the nonisolated keyword.  This allows it to run off of the main actor.
extension OpenSkyResponse: Decodable {
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
