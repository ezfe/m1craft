//
//  AuthView.swift
//  M1Craft UI
//
//  Created by Ezekiel Elin on 11/11/21.
//

import Foundation
import AuthenticationServices
import SwiftUI
import InstallationManager
import Common

struct RefreshAuthView: View {
	@EnvironmentObject
	var appState: AppState
	
	@State
	var signingIn = false
	@State
	var message = ""
	
	var body: some View {
		VStack {
			if signingIn {
				Text("Retrieving Minecraft Credentials...")
				ProgressView()
			} else {
				Text(message)
			}
		}
		.onAppear(perform: {
			signingIn = true
			print("Attempting refresh for \(appState.azureRefreshToken)")
			Task {
				var refreshUrl = authRefreshUrl
				let queryItems = [URLQueryItem(name: "refreshToken", value: appState.azureRefreshToken)]
				
				if #available(macOS 13.0, *) {
					refreshUrl.append(queryItems: queryItems)
				} else {
					var components = URLComponents(url: refreshUrl, resolvingAgainstBaseURL: false)
					components?.queryItems = queryItems
					guard let _refreshUrl = components?.url else {
						print("Failed to build refresh token. Resetting.")
						appState.azureRefreshToken = ""
						return
					}
					refreshUrl = _refreshUrl
				}
				
				let request = URLRequest(url: refreshUrl)
				let (data, response) = try await URLSession.shared.data(for: request)
				
				let code = (response as? HTTPURLResponse)?.statusCode
				
				if let code = code {
					do {
						if code == 200 {
							let results = try JSONDecoder().decode(SignInResult.self, from: data)
							appState.azureRefreshToken = results.refresh
							appState.credentials = results
						} else {
							let response = try JSONDecoder().decode(PreflightResponse.self, from: data)
							message = response.message
						}
					} catch let err {
						message = err.localizedDescription
					}
				} else {
					message = "An unexpected error occurred."
				}
				
				signingIn = false
			}
		})
		.padding()
	}
}
