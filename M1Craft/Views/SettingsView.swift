//
//  SettingsView.swift
//  M1Craft
//
//  Created by Ezekiel Elin on 1/20/22.
//

import SwiftUI
import InstallationManager

struct SettingsView: View {
	@EnvironmentObject
	var appState: AppState
	
	var body: some View {
		VStack {
			if let credentials = appState.credentials {
				Text("Currently signed in as: \(credentials.name)")
				Button("Sign out") {
					appState.azureRefreshToken = ""
					appState.credentials = nil
				}
			} else {
				Text("Currently signed out.")
			}
			Divider()

			Stepper(value: $appState.selectedMemoryAllocation,
					in: 1...16,
					step: 1) {
				Text("Memory Allocation: \(appState.selectedMemoryAllocation)GB")
			}
		}
	}
}
