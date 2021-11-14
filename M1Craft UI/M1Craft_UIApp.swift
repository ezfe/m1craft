//
//  M1Craft_UIApp.swift
//  M1Craft UI
//
//  Created by Ezekiel Elin on 10/18/21.
//

import SwiftUI
import InstallationManager

@main
struct M1Craft_UIApp: App {
    
    @State
    var credentials: SignInResult? = nil
    
    var body: some Scene {
        WindowGroup {
            if let credentials = credentials {
                ContentView(credentials: credentials)
            } else {
                AuthView(credentials: $credentials)
            }
        }
    }
}
