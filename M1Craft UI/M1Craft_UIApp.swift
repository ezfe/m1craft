//
//  M1Craft_UIApp.swift
//  M1Craft UI
//
//  Created by Ezekiel Elin on 10/18/21.
//

import SwiftUI
import InstallationManager

@main
struct M1Craft_UIApp: App {
    
    @State
    var preflightCompleted = false
    
    @State
    var credentials: SignInResult? = nil

    @AppStorage("azure_refresh_token")
    var azureRefreshToken: String = ""
    
    @State
    var launcherDirectory: URL? = nil
    @State
    var minecraftDirectory: URL? = nil
    @State
    var jsonData: Data? = nil
    
    @StateObject
    var updaterViewModel = UpdaterViewModel()
    
    var body: some Scene {
        WindowGroup {
            VStack {
                if azureRefreshToken.count > 0 || credentials != nil {
                    if let credentials = credentials {
                        Text("Currently signed in as: \(credentials.name)")
                    } else {
                        Text("Currently signed in.")
                    }
                    Button("Sign out") {
                        azureRefreshToken = ""
                        self.credentials = nil
                    }
                    Divider()
                }

                if !preflightCompleted {
                    Preflight(preflightCompleted: $preflightCompleted)
                } else if let credentials = credentials {
                    ContentView(credentials: credentials,
                                launcherDirectory: $launcherDirectory,
                                minecraftDirectory: $minecraftDirectory,
                                jsonData: $jsonData)
                } else if azureRefreshToken.count > 0 {
                    RefreshAuthView(credentials: $credentials,
                                    azureRefreshToken: $azureRefreshToken)
                } else {
                    AuthView(credentials: $credentials)
                }
            }
            .onAppear {
                NSWindow.allowsAutomaticWindowTabbing = false
            }
            .frame(minWidth: 500,
                   maxWidth: .infinity,
                   minHeight: 350,
                   maxHeight: .infinity)
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updaterViewModel: updaterViewModel)
            }
            CommandGroup(after: .importExport) {
                if launcherDirectory == nil || minecraftDirectory == nil || jsonData == nil {
                    Group {
                        Text("Run the game to access directories or export JSON data")
                    }
                } else {
                    Group {
                        Button("Open launcher directory") {
                            if let ld = launcherDirectory {
                                NSWorkspace.shared.open(ld)
                            }
                        }.disabled(launcherDirectory == nil)
                        Button("Open minecraft directory") {
                            if let md = minecraftDirectory {
                                NSWorkspace.shared.open(md)
                            }
                        }.disabled(minecraftDirectory == nil)
                    }
                    Group {
                        Button("Export modified version JSON...") {
                            let savePanel = NSSavePanel()
                            savePanel.allowedContentTypes = [.json]
                            savePanel.canCreateDirectories = true
                            savePanel.isExtensionHidden = false
                            savePanel.allowsOtherFileTypes = false
                            savePanel.title = "Save Version JSON"
                            savePanel.directoryURL = minecraftDirectory?.appendingPathComponent("versions")
                            savePanel.nameFieldLabel = "File name:"
                            
                            let response = savePanel.runModal()
                            if let url = savePanel.url {
                                try? jsonData?.write(to: url)
                            }
                        }.disabled(jsonData == nil)
                    }
                }
            }
        }
    }
}
