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
    
    @State
    var preflightCompleted = false
    
    @State
    var credentials: SignInResult? = nil

    @AppStorage("azure_refresh_token")
    var azureRefreshToken: String = ""
    
    @AppStorage("selected-version")
    var selectedVersion: VersionManifest.VersionType = .release

    @State
    var launcherDirectory: URL? = nil
    @State
    var minecraftDirectory: URL? = nil
    
    @StateObject
    var updaterViewModel = UpdaterViewModel()
    
    @State
    var alertPresented = false
    @State
    var alertTitle = ""
    @State
    var alertMessage: String? = nil
    
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
                                minecraftDirectory: $minecraftDirectory)
                } else if azureRefreshToken.count > 0 {
                    RefreshAuthView(credentials: $credentials,
                                    azureRefreshToken: $azureRefreshToken)
                } else {
                    AuthView(credentials: $credentials)
                }
            }
            .alert(isPresented: $alertPresented, content: {
                if let alertMessage = alertMessage {
                    return Alert(title: Text(alertTitle), message: Text(alertMessage))
                } else {
                    return Alert(title: Text(alertTitle), dismissButton: nil)
                }
            })
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
                if launcherDirectory == nil || minecraftDirectory == nil {
                    Group {
                        Text("Run the game to access directories")
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
                        
                        alertTitle = "Preparing JSON..."
                        alertPresented = true
                        
                        if let url = savePanel.url, response == .OK {
                            Task {
                                do {
                                    let manifest = try await VersionManifest.download()
                                    let metadata = try manifest.metadata(for: selectedVersion)
                                    let package = try await metadata.package(patched: true)

                                    let encoder = JSONEncoder()
                                    encoder.dateEncodingStrategy = .iso8601
                                    let data = try encoder.encode(package)

                                    try data.write(to: url)
                                    
                                    alertTitle = "Saved JSON"
                                } catch let err {
                                    alertTitle = "Failed to save JSON"
                                    alertMessage = err.localizedDescription
                                }
                            }
                        } else {
                            alertPresented = false
                        }
                    }
                }
            }
        }
    }
}
