//
//  OpenSkyUtah_2025App.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import SwiftUI

@main
struct OpenSkyUtah_2025App: App {
    var body: some Scene {
        WindowGroup {
            OpenSkyUtahView(openSkyService: OpenSkyService())
        }
    }
}
