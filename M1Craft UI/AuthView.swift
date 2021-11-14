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

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }

    func signIn() async -> SignInResult {
        let clientId = "92188479-b731-4baa-b4cb-2aad9a47d10f"
        let redirectUri = "https://m1craft-server.ezekiel.workers.dev/auth"
        let scope = "XboxLive.signin%20offline_access"
        let sentState = UUID()

        let callbackUrl: URL? = try? await withCheckedThrowingContinuation { continuation in
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
        
        let fakeuuid = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let faketoken = UUID().uuidString
        guard let callbackUrl = callbackUrl else {
            print("Failed to complete auth")
            return SignInResult(id: fakeuuid, name: "AuthFailure", token: faketoken)
        }
        
        let components = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems
  
        let id = queryItems?.first(where: { $0.name == "id" })?.value
        let name = queryItems?.first(where: { $0.name == "name" })?.value
        let token = queryItems?.first(where: { $0.name == "token" })?.value
        let error = queryItems?.first(where: { $0.name == "error" })?.value

        guard let id = id, let name = name, let token = token else {
            print(error ?? "Unknown error")
            return SignInResult(id: fakeuuid, name: "AuthFailure", token: faketoken)
        }
        
        return SignInResult(id: id, name: name, token: token)
    }
}

struct AuthView: View {
    @StateObject var viewModel = SignInViewModel()
    
    @Binding
    var credentials: SignInResult?
    
    var body: some View {
        Button("Sign In") {
            Task {
                print("Clicked button...")
                let res = await viewModel.signIn()
                credentials = res
            }
        }.padding()
    }
}
