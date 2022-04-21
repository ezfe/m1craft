//
//  ContentView.swift
//  M1Craft UI
//
//  Created by Ezekiel Elin on 10/17/21.
//

import SwiftUI
import InstallationManager
import Common

extension VersionManifest.VersionType: RawRepresentable {
    public init?(rawValue: String) {
        if rawValue == "__release" {
            self = .release
        } else if rawValue == "__snapshot" {
            self = .snapshot
        } else {
            self = .custom(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
            case .release:
                return "__release"
            case .snapshot:
                return "__snapshot"
            case .custom(let version):
                return version
        }
    }
}

struct ContentView: View {
    @EnvironmentObject
    var appState: AppState
    
    @State
    var availableVersions: [VersionManifest.VersionType] = [.release, .snapshot]
    
    @AppStorage("selected-memory-allocation")
    var selectedMemoryAllocation: Int = 3
    
    @State
    var startedDownloading = false

    var body: some View {
        VStack {
            Form {
//                Picker(selection: $selectedVersion, label: Text("Auto Version:")) {
//                    Text("Latest Release").tag(VersionManifest.VersionType.release)
//                    Text("Latest Snapshot").tag(VersionManifest.VersionType.snapshot)
//                }
//                .pickerStyle(.radioGroup)

                if !availableVersions.isEmpty {
//                    Picker(selection: $selectedVersion, label: Text("Custom Version:")) {
//                        ForEach(availableVersions, id: \.hashValue) { v in
//                            switch v {
//                                case .custom(let s):
//                                    Text(s).tag(v)
//                                case .snapshot:
//                                    Text("Latest Snapshot").tag(v)
//                                case .release:
//                                    Text("Latest Release").tag(v)
//                            }
//                        }
//                    }
//                    .scaledToFit()
//                    .pickerStyle(.menu)
                }
                
                Button {
//                    runGame()
                } label: {
//                    switch selectedVersion {
//                        case .custom(let v):
//                            Text("Launch \(v)")
//                        case .release:
//                            Text("Launch Latest Release")
//                        case .snapshot:
//                            Text("Launch Latest Snapshot")
//                    }
                    Image(systemName: "play.circle")
                }
                .disabled(startedDownloading)
            }
            .disabled(startedDownloading)
            
            if startedDownloading {
                Divider()

                ProgressView("Java Runtime and Main Jar", value: appState.javaDownload)
                ProgressView("Java Libraries", value: appState.libraryDownload)
                ProgressView("Assets", value: appState.assetDownload)
            }
            
//            if let message = message, !message.contains("Starting game") {
//                Divider()
//                Text(message)
//                Text("If a network/time-out error occurred, simply re-start the game. It will resume where it left off")
//            }
        }
        .padding()
        .onAppear {
            Task {
                let manifest = try await VersionManifest.download(url: manifestUrl)
                if let _earliestReleaseTime = manifest.versions.first(where: { $0.id == "19w11a" })?.releaseTime {
                    availableVersions = [.release, .snapshot]
                    let newVersions = manifest.versions
                        .filter { $0.releaseTime >= _earliestReleaseTime }
                        .map { VersionManifest.VersionType.custom($0.id) }
                    availableVersions.append(contentsOf: newVersions)
                }
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(
//            credentials: SignInResult(
//                id: "uuidhere",
//                name: "ezfe",
//                token: "123456.67890",
//                refresh: "962312.134134"
//            ),
//            launcherDirectory: .constant(nil),
//            minecraftDirectory: .constant(nil)
//        )
//    }
//}
