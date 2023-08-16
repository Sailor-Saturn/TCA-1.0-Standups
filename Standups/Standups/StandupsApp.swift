//
//  StandupsApp.swift
//  Standups
//
//  Created by Vera Dias on 16/08/2023.
//

import SwiftUI
import ComposableArchitecture

@main
struct StandupsApp: App {
    var body: some Scene {
        WindowGroup {
            StandupsListView(store: Store(initialState: StandupsListFeature.State(
                standups: [.mock]
              )){
                StandupsListFeature()
            })
        }
    }
}
