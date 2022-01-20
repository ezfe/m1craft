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
    var availableVersions: [VersionManifest.VersionType] = [.release, .snapshot]

    @AppStorage("selected-version")
    var selectedVersion: VersionManifest.VersionType = .release
    
    @AppStorage("selected-memory-allocation")
    var selectedMemoryAllocation: Int = 3
    
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
    
    var body: some View {
        VStack {
            Form {
                Picker(selection: $selectedVersion, label: Text("Auto Version:")) {
                    Text("Latest Release").tag(VersionManifest.VersionType.release)
                    Text("Latest Snapshot").tag(VersionManifest.VersionType.snapshot)
                }
                .pickerStyle(.radioGroup)

                if !availableVersions.isEmpty {
                    Picker(selection: $selectedVersion, label: Text("Custom Version:")) {
                        ForEach(availableVersions, id: \.hashValue) { v in
                            switch v {
                                case .custom(let s):
                                    Text(s).tag(v)
                                case .snapshot:
                                    Text("Latest Snapshot").tag(v)
                                case .release:
                                    Text("Latest Release").tag(v)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                }
                
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
                let manifest = try await VersionManifest.download()
                if let _1165_releasetime = manifest.versions.first(where: { $0.id == "1.16.5" })?.releaseTime {
                    availableVersions = [.release, .snapshot]
                    let newVersions = manifest.versions
                        .filter { $0.releaseTime >= _1165_releasetime }
                        .map { VersionManifest.VersionType.custom($0.id) }
                    availableVersions.append(contentsOf: newVersions)
                }
            }
        }
    }
    
    func runGame() {
        startedDownloading = true
        message = nil

        Task {
            let installationManager = try InstallationManager()
            
            print(installationManager.baseDirectory.path)
            
            launcherDirectory = installationManager.baseDirectory
            minecraftDirectory = installationManager.gameDirectory
            
            let clientJar: URL
            
            do {
                let manifest = try await VersionManifest.download()
                let metadata = try manifest.metadata(for: selectedVersion)
                
                let package = try await metadata.package(patched: true)
                guard package.minimumLauncherVersion >= 21 else {
                    message = "Unfortunately, \(package.id) isn't available from this utility. This utility does not work with versions prior to 1.13"
                    return
                }
                                
                javaDownload = 0.10
                
                clientJar = try await installationManager.downloadJar(for: package)
                javaDownload = 0.4

                let _ = try await installationManager.downloadJava(for: package)
                javaDownload = 1
                
                try await installationManager.downloadAssets(for: package, progress: { progress in
                    assetDownload = progress
                })
                let _ = try await installationManager.downloadLibraries(for: package, progress: { progress in
                    libraryDownload = progress
                })

                print("Queued up downloads")
                
                try installationManager.copyNatives()
                
                let launchArgumentsResults = try await installationManager.launchArguments(
                    for: package,
                    with: credentials,
                    clientJar: clientJar,
                    memory: UInt8(selectedMemoryAllocation)
                )
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
            minecraftDirectory: .constant(nil)
        )
    }
}
