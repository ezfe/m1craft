//
//  SettingsView.swift
//  M1Craft
//
//  Created by Ezekiel Elin on 1/20/22.
//

import SwiftUI
import InstallationManager

struct SettingsView: View {
    @Binding
    var azureRefreshToken: String
    @Binding
    var credentials: SignInResult?
    
    @AppStorage("selected-memory-allocation")
    var selectedMemoryAllocation: Int = 3
    
    var body: some View {
        VStack {
            if let credentials = credentials {
                Text("Currently signed in as: \(credentials.name)")
            } else {
                Text("Currently signed in.")
            }
            Button("Sign out") {
                azureRefreshToken = ""
                credentials = nil
            }
            Divider()

            Stepper(value: $selectedMemoryAllocation,
                    in: 1...16,
                    step: 1) {
                Text("Memory Allocation: \(selectedMemoryAllocation)GB")
            }
        }
    }
}
