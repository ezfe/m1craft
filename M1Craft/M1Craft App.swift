//
//  M1Craft_UIApp.swift
//  M1Craft UI
//
//  Created by Ezekiel Elin on 10/18/21.
//

import SwiftUI
import InstallationManager

@main
struct M1CraftApp: App {
    @StateObject
    private var appState: AppState
        
    @StateObject
    var updaterViewModel = UpdaterViewModel()
    
    @MainActor
    init() {
        self._appState = StateObject(wrappedValue: AppState())
    }
    
    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environmentObject(appState)
                .frame(minWidth: 500,
                       maxWidth: .infinity,
                       minHeight: 350,
                       maxHeight: .infinity)
                .alert(isPresented: $appState.alertPresented, content: {
                    if let alertMessage = appState.alertMessage {
                        return Alert(title: Text(appState.alertTitle), message: Text(alertMessage), dismissButton: nil)
                    } else {
                        return Alert(title: Text(appState.alertTitle), dismissButton: nil)
                    }
                })
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    Task { await appState.setup() }
                }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updaterViewModel: updaterViewModel)
            }
            CommandGroup(after: .importExport) {
                Group {
                    Button("Open launcher directory") {
                        if let ld = appState.launcherDirectory {
                            NSWorkspace.shared.open(ld)
                        }
                    }.disabled(appState.launcherDirectory == nil)
                    Button("Open minecraft directory") {
                        if let md = appState.minecraftDirectory {
                            NSWorkspace.shared.open(md)
                        }
                    }.disabled(appState.minecraftDirectory == nil)
                }
            }
        }
    }
}
