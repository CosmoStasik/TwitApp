//
//  TwitAppApp.swift
//  TwitApp
//
//  Created by Stanislav Sobolevsky on 15.12.22.
//

import SwiftUI
import Firebase


@main
struct TwitApp: App {
    init() {
        FirebaseApp.configure() // Initializing FireBase
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
