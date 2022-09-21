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

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {

	func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
		return ASPresentationAnchor()
	}

	func signIn() async throws -> SignInResult {
		let sentState = UUID()

		let callbackUrl: URL = try await withCheckedThrowingContinuation { continuation in
			   var components = URLComponents(url: authStartUrl, resolvingAgainstBaseURL: false)!
			components.queryItems = [URLQueryItem(name: "state", value: sentState.description)]
			let url = components.url!
			
			let authSession = ASWebAuthenticationSession(
				url: url,
				callbackURLScheme: "m1craft") { (url, error) in
					print("Callback...")
					if let url = url {
						continuation.resume(returning: url)
					} else if let error = error {
						continuation.resume(throwing: error)
					} else {
						print("Received no URL or error! Illegal state.")
					}
				}
			
			authSession.presentationContextProvider = self

			DispatchQueue.main.async {
				authSession.start()
				print("Started session...")
			}
		}
		
		let components = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: false)!
		let queryItems = components.queryItems
  
		let resultBase64 = queryItems?.first(where: { $0.name == "signInResult" })?.value
		let error = queryItems?.first(where: { $0.name == "error_message" })?.value

		guard let resultBase64 = resultBase64 else {
			throw CError.unknownError(error ?? "Unknown error")
		}
		 
		 guard let data = Data(base64Encoded: resultBase64) else {
			 throw CError.decodingError("Failed to decode base-64: \(resultBase64)")
		 }
		 
		 do {
			 let signInResult = try JSONDecoder().decode(SignInResult.self, from: data)
			 UserDefaults.standard.set(signInResult.refresh, forKey: "azure_refresh_token")
			  
			  return signInResult
		 } catch let err {
			 throw CError.decodingError("Failed to decode SignInResult: \(err.localizedDescription)")
		 }
	}
}

struct AuthView: View {
	@EnvironmentObject
	var appState: AppState
	
	@StateObject
	var viewModel = SignInViewModel()
	
	@State
	var signingIn = false
	@State
	var errorMessageShown = false
	@State
	var errorMessage = ""
	
	var body: some View {
		VStack {
			if signingIn {
				Text("Complete login to continue.")
				Text("If no window appears, quit Safari and try again.")
				ProgressView()
			} else {
				Button("Sign In") {
					Task {
						signingIn = true
						do {
							let res = try await viewModel.signIn()
							print("Received res; Saving...", res)
							appState.credentials = res
						} catch let error {
							if let asError = error as? ASWebAuthenticationSessionError {
								switch asError.code {
									case .canceledLogin:
										errorMessage = "Login cancelled."
									default:
										errorMessage = "An unknown error occurred. Please quit Safari and try again."
								}
							} else if let cError = error as? CError {
								errorMessage = cError.errorText
							} else {
								errorMessage = error.localizedDescription
							}
							errorMessageShown = true
						}
						signingIn = false
					}
				}
			}
		}
		.alert("Authentication Error", isPresented: $errorMessageShown, actions: {
			Button {
				errorMessageShown = false
				appState.credentials = nil
			} label: {
				Text("OK")
			}
		}, message: {
			Text(errorMessage)
		})
		.padding()
	}
}
