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
    var credentials: SignInResult
    
    @State
    var availableVersions: [String] = []
    @AppStorage("selected-version")
    var selectedVersion: VersionManifest.VersionType = .release
    
    @State
    var startedDownloading = false
    
    @State
    var javaDownload: Double = 0
    @State
    var libraryDownload: Double = 0
    @State
    var assetDownload: Double = 0
    
    @State
    var message: String? = nil
    
    @Binding
    var launcherDirectory: URL?
    @Binding
    var minecraftDirectory: URL?
    
    @Binding
    var jsonData: Data?
    
    var body: some View {
        VStack {
            Form {
                Picker(selection: $selectedVersion, label: Text("Auto Version:")) {
                    Text("Latest Release").tag(VersionManifest.VersionType.release)
                    Text("Latest Snapshot").tag(VersionManifest.VersionType.snapshot)
                    Text("1.17.1").tag(VersionManifest.VersionType.custom("1.17.1"))
                    Text("1.18").tag(VersionManifest.VersionType.custom("1.18"))
                }
                .pickerStyle(.radioGroup)

                /*
                Picker(selection: $selectedVersion, label: Text("Custom Version:")) {
                    ForEach(availableVersions, id: \.hashValue) { v in
                        Text(v).tag(VersionManifest.VersionType.custom(v))
                    }
                }
                .pickerStyle(.menu)
                 */
                
                Button {
                    runGame()
                } label: {
                    switch selectedVersion {
                        case .custom(let v):
                            Text("Launch \(v)")
                        case .release:
                            Text("Launch Latest Release")
                        case .snapshot:
                            Text("Launch Latest Snapshot")
                    }
                    Image(systemName: "play.circle")
                }
                .disabled(startedDownloading)
            }
            .disabled(startedDownloading)
            
            if startedDownloading {
                Divider()

                ProgressView("Java Runtime and Main Jar", value: javaDownload)
                ProgressView("Java Libraries", value: libraryDownload)
                ProgressView("Assets", value: assetDownload)
            }
            
            if let message = message, !message.contains("Starting game") {
                Divider()
                Text(message)
                Text("If a network/time-out error occurred, simply re-start the game. It will resume where it left off")
            }
        }
        .padding()
        .onAppear {
            Task {
                let installationManager = try InstallationManager()
                availableVersions = try await installationManager
                    .availableVersions(.mojang)
                    .map { $0.id }
            }
        }
    }
    
    func runGame() {
        startedDownloading = true
        message = nil

        Task {
            let installationManager = try InstallationManager()
            installationManager.use(version: selectedVersion)
            
            print(installationManager.baseDirectory.path)
            
            launcherDirectory = installationManager.baseDirectory
            minecraftDirectory = installationManager.gameDirectory
            
            do {
                let versionInfo = try await installationManager.downloadVersionInfo(.mojang)
                guard versionInfo.minimumLauncherVersion >= 21 else {
                    message = "Unfortunately, \(versionInfo.id) isn't available from this utility. This utility does not work with versions prior to 1.13"
                    return
                }
                
                if let package = installationManager.version {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    jsonData = try? encoder.encode(package)
                }
                
                javaDownload = 0.10
                
                try await installationManager.downloadJar()
                javaDownload = 0.4

                let _ = try await installationManager.downloadJava(.mojang)
                javaDownload = 1
                
                try await installationManager.downloadAssets { progress in
                    assetDownload = progress
                }
                let _ = try await installationManager.downloadLibraries { progress in
                    libraryDownload = progress
                }
            } catch let err {
                
                startedDownloading = false
                javaDownload = 0
                libraryDownload = 0
                assetDownload = 0

                if let cerr = err as? CError {
                    switch cerr {
                        case .networkError(let errorMessage):
                            message = "Network Error: \(errorMessage)"
                        case .encodingError(let errorMessage):
                            message = "Encoding Error: \(errorMessage)"
                        case .decodingError(let errorMessage):
                            message = "Decoding Error: \(errorMessage)"
                        case .filesystemError(let errorMessage):
                            message = "Filesystem Error: \(errorMessage)"
                        case .stateError(let errorMessage):
                            message = "State Error: \(errorMessage)"
                        case .sha1Error(let expected, let found):
                            message = "SHA1 Mismatch: Expected \(expected) but found \(found)"
                        case .unknownVersion(let version):
                            message = "Unknown Version: \(version)"
                        case .unknownError(let errorMessage):
                            message = errorMessage
                    }
                } else {
                    message = err.localizedDescription
                }

                return
            }

            print("Queued up downloads")
            
            try installationManager.copyNatives()
            
            let launchArgumentsResults = installationManager.launchArguments(with: credentials)
            switch launchArgumentsResults {
                case .success(let args):
                    // java
                    let javaBundle = installationManager.javaBundle!
                    let javaExec = javaBundle.appendingPathComponent("Contents/Home/bin/java", isDirectory: false)
                    
                    let proc = Process()
                    proc.executableURL = javaExec
                    proc.arguments = args
                    proc.currentDirectoryURL = installationManager.baseDirectory

//                    let pipe = Pipe()
//                    proc.standardOutput = pipe
                    
                    print(javaExec.absoluteString)
                    print(args.joined(separator: " "))
                    print(installationManager.baseDirectory.absoluteString)
                    
                    message = "Starting game..."
                    proc.launch()

                    proc.waitUntilExit()
                    
                    startedDownloading = false
                    javaDownload = 0
                    libraryDownload = 0
                    assetDownload = 0
                    message = nil
                case .failure(let error):
                    print(error)
                    return
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            credentials: SignInResult(
                id: "uuidhere",
                name: "ezfe",
                token: "123456.67890",
                refresh: "962312.134134"
            ),
            launcherDirectory: .constant(nil),
            minecraftDirectory: .constant(nil),
            jsonData: .constant(nil))
    }
}
