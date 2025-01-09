//
//  ContentView.swift
//  ModulationPlayground
//
//  Created by Mitch on 09.01.25.
//

import SwiftUI

struct ContentView: View {

    let modulator: Modulator

    var body: some View {
        VStack {
            Button("Play") {
                Task {
                    try await modulator.playSound()
                }
            }
        }
        .task {
            try? modulator.setUp()
        }
        .onDisappear {
            try? modulator.tearDown()
        }
    }
}

#Preview {
    ContentView(modulator: PreviewModulator())
}
