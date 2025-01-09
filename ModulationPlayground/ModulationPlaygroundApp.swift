//
//  ModulationPlaygroundApp.swift
//  ModulationPlayground
//
//  Created by Mitch on 09.01.25.
//

import SwiftUI

@main
struct ModulationPlaygroundApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(modulator: AudioToolboxModulator())
        }
    }
}
