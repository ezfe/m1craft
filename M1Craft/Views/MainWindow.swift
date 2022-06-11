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
    var viewSettings = false
    @State
    var loginSheet = true
    
    var body: some View {
        Preflight()
            .environmentObject(appState)
            .toolbar {
                ToolbarItemGroup(placement: .status) {
                    Button {
                        viewSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .help("Open Settings")
                }
            }
            .sheet(isPresented: $viewSettings) {
                VStack {
                    SettingsView()
                    HStack {
                        Spacer()
                        Button("Close") {
                            viewSettings = false
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                }
                .padding()
            }
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow()
    }
}
