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
        let clientId = "92188479-b731-4baa-b4cb-2aad9a47d10f"
        let redirectUri = "\(serverAddress)/auth"
        let scope = "XboxLive.signin%20offline_access"
        let sentState = UUID()

        let callbackUrl: URL = try await withCheckedThrowingContinuation { continuation in
            let url = URL(string: "https://login.live.com/oauth20_authorize.srf?client_id=\(clientId)&response_type=code&redirect_uri=\(redirectUri)&scope=\(scope)&state=\(sentState)")!
            print("Build URL")
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

            authSession.start()
            print("Started session...")
        }
        
        let components = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems
  
        let id = queryItems?.first(where: { $0.name == "id" })?.value
        let name = queryItems?.first(where: { $0.name == "name" })?.value
        let token = queryItems?.first(where: { $0.name == "token" })?.value
        let refresh = queryItems?.first(where: { $0.name == "refresh" })?.value
        let error = queryItems?.first(where: { $0.name == "error_message" })?.value

        guard let id = id, let name = name, let token = token, let refresh = refresh else {
            throw CError.unknownError(error ?? "Unknown error")
        }
        
        UserDefaults.standard.set(refresh, forKey: "azure_refresh_token")
        
        return SignInResult(id: id, name: name, token: token, refresh: refresh)
    }
}

struct AuthView: View {
    @StateObject
    var viewModel = SignInViewModel()
    
    @Binding
    var credentials: SignInResult?
    
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
                            credentials = res
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
                credentials = nil
            } label: {
                Text("OK")
            }
        }, message: {
            Text(errorMessage)
        })
        .padding()
    }
}
