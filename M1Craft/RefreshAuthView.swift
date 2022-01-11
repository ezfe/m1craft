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
    @Binding
    var credentials: SignInResult?
    
    @Binding
    var azureRefreshToken: String
    
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
            print("Attempting refresh for \(azureRefreshToken)")
            Task {
                var components = URLComponents(string: "\(serverAddress)/refresh-auth")
                components?.queryItems = [
                    URLQueryItem(name: "refresh_token", value: azureRefreshToken)
                ]
                guard let refreshUrl = components?.url else {
                    print("Failed to build refresh token. Resetting.")
                    azureRefreshToken = ""
                    return
                }
                
                var request = URLRequest(url: refreshUrl)
                request.httpMethod = "post"
                let (data, response) = try await URLSession.shared.data(for: request)
                
                let code = (response as? HTTPURLResponse)?.statusCode
                
                if let code = code {
                    do {
                        if code == 200 {
                            let results = try JSONDecoder().decode(SignInResult.self, from: data)
                            azureRefreshToken = results.refresh
                            credentials = results
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
