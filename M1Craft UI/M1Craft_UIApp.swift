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
    var preflightCompleted = false
    
    @State
    var credentials: SignInResult? = nil
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if !preflightCompleted {
                    Preflight(preflightCompleted: $preflightCompleted)
                } else if let credentials = credentials {
                    ContentView(credentials: credentials)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    AuthView(credentials: $credentials)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}
