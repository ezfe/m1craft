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
    @Binding
    var preflightCompleted: Bool
    
    @State
    var loading = true
    @State
    var message = ""
    @State
    var messageUrl: URL? = nil
    
    var body: some View {
        VStack {
            if loading {
                Text("Loading...")
                ProgressView()
            } else {
                Text(message)
                if let url = messageUrl {
                    Link("Continue...", destination: url)
                }
            }
        }
        .onAppear {
            Task { await performPreflight() }
        }
        .padding()
    }
    
    func performPreflight() async {
        loading = true
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        var components = URLComponents(string: "https://m1craft-server.ezekiel.workers.dev/preflight")
        components?.queryItems = [URLQueryItem(name: "app_version", value: appVersion)]
        
        let response = try? await URLSession.shared.data(from: components!.url!)
        if let response = response {
            let data = response.0
            let decoded = try? JSONDecoder().decode(PreflightResponse.self, from: data)
            
            guard let decoded = decoded else {
                preflightCompleted = true
                return
            }

            message = decoded.message
            messageUrl = decoded.url
            loading = false
        } else {
            preflightCompleted = true
        }
    }
}
