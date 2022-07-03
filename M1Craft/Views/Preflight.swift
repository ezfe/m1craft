//
//  Preflight.swift
//  M1Craft UI
//
//  Created by Ezekiel Elin on 11/14/21.
//

import SwiftUI

struct PreflightResponse: Decodable {
	var message: String
	var url: URL?
}

struct Preflight: View {
	@EnvironmentObject
	var appState: AppState
		
	var body: some View {
		switch appState.initializationStatus {
			case .idle, .downloading:
				Text("Loading...")
				ProgressView()
			case .failure(let result):
				Text(result.message)
				if let url = result.url {
					Link("Continue...", destination: url)
				}
			case .success(let manifest):
				if appState.credentials != nil {
					VersionListView(
						selectedVersionId: .constant(""),
						manifest: manifest
					)
					.environmentObject(appState)
				} else if appState.azureRefreshToken.count > 0 {
					RefreshAuthView()
						.environmentObject(appState)
				} else {
					AuthView()
						.environmentObject(appState)
				}
		}
	}
}
