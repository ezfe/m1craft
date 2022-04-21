//
//  MainWindow.swift
//  M1Craft
//
//  Created by Ezekiel Elin on 2/23/22.
//

import SwiftUI

struct MainWindow: View {
    @EnvironmentObject
    var appState: AppState

    @State
    var viewAccount = false
    @State
    var loginSheet = true
    
    var body: some View {
        Preflight()
            .environmentObject(appState)
            .toolbar {
                ToolbarItemGroup(placement: .status) {
                    Button {
                        viewAccount = true
                    } label: {
                        Label("Account Info", systemImage: "person.circle")
                    }
                    .help("Open Account Info")
                }
            }
            .sheet(isPresented: $viewAccount) {
                VStack {
                    accountView()
                        .environmentObject(appState)
                    HStack {
                        Spacer()
                        Button("Close") {
                            viewAccount = false
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                }
                .padding()
            }
    }
    
    @ViewBuilder
    private func accountView() -> some View {
        if let credentials = appState.credentials {
            Text("Account: \(credentials.name)")
        } else {
            Text("Not logged in, hmm")
        }
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow()
    }
}
