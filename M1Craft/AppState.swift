//
//  AppState.swift
//  M1Craft
//
//  Created by Ezekiel Elin on 2/23/22.
//

import Foundation
import InstallationManager
import SwiftUI
import Common

enum PreflightStatus {
    case failure(PreflightResponse)
    case success
}

enum InitStatus {
    case idle
    case downloading
    case success(VersionManifest)
    case failure(PreflightResponse)
}

enum LaunchStatus {
    case idle
    case starting
    case running
    case failed(String)
}

@MainActor
class AppState: ObservableObject {
    @Published
    var initializationStatus: InitStatus = .idle
    @Published
    var launchStatus: LaunchStatus = .idle
    
    @Published
    var launcherDirectory: URL? = nil
    @Published
    var minecraftDirectory: URL? = nil
    
    @State
    var javaDownload: Double = 0
    @State
    var libraryDownload: Double = 0
    @State
    var assetDownload: Double = 0
    
//    @AppStorage("selected-version")
//    var selectedVersion: VersionManifest.VersionType = .release
    @AppStorage("azure_refresh_token")
    var azureRefreshToken: String = ""
    @AppStorage("selected-version")
    var selectedVersions: [VersionManifest.VersionType] = [.release]
    @AppStorage("selected-memory-allocation")
    var selectedMemoryAllocation: Int = 3
    
    @Published
    var credentials: SignInResult? = nil
    
    init() {
        
    }
    
    func setup() async {
        guard case .idle = initializationStatus else {
            return
        }

        let preflightStatus = await preflight()
        if case .failure(let result) = preflightStatus {
            self.initializationStatus = .failure(result)
            return
        }

        do {
            let manifest = try await VersionManifest.download(url: manifestUrl)
            self.initializationStatus = .success(manifest)
        } catch let err {
            print(err)
            // TODO: Improve this flow
            self.initializationStatus = .failure(PreflightResponse(message: err.localizedDescription))
        }
        
        if let im = try? InstallationManager() {
            self.launcherDirectory = im.baseDirectory
            self.minecraftDirectory = im.gameDirectory
        } else {
            print("Failed to create InstallationManager")
        }
    }
    
    private func preflight() async -> PreflightStatus {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        var components = URLComponents(string: "\(serverAddress)/preflight")
        components?.queryItems = [URLQueryItem(name: "app_version", value: appVersion)]
        
        let response = try? await URLSession.shared.data(from: components!.url!)
        if let response = response {
            let data = response.0
            let decoded = try? JSONDecoder().decode(PreflightResponse.self, from: data)
            
            guard let decoded = decoded else {
                // Don't interrupt user if the message
                // fails to download or decode.
                return .success
            }
            
            return .failure(decoded)
        } else {
            return .success
        }
    }
    
    func runGame(metadata: VersionManifest.VersionMetadata) async {
        print("Running \(metadata.id)")
        self.launchStatus = .starting

        guard let credentials = credentials else {
            print("Not logged in")
            self.launchStatus = .failed("Not logged in")
            return
        }
                
        do {
            let installationManager = try InstallationManager()
            
            print("Patching")
            let package = try await metadata.package(patched: true)
            guard package.minimumLauncherVersion >= 21 else {
                self.launchStatus = .failed("Unfortunately, \(package.id) isn't available from this utility. This utility does not work with versions prior to 1.13")
                return
            }
            
            print("Starting Java Download")
                            
            self.javaDownload = 0.10
            
            let clientJar = try await installationManager.downloadJar(for: package)
            self.javaDownload = 0.4

            let _ = try await installationManager.downloadJava(for: package)
            self.javaDownload = 1
            
            print("Starting Asset Download")
            try await installationManager.downloadAssets(for: package, progress: { [weak self] progress in
                self?.assetDownload = progress
            })
            
            print("Starting Library Download")
            let _ = try await installationManager.downloadLibraries(for: package, progress: { [weak self] progress in
                self?.libraryDownload = progress
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
                    
                    proc.launch()

                    proc.waitUntilExit()
                    
                    self.launchStatus = .running
                    self.javaDownload = 0
                    self.libraryDownload = 0
                    self.assetDownload = 0
                case .failure(let error):
                    self.launchStatus = .failed(error.localizedDescription)
                    return
            }
        } catch let err {
            javaDownload = 0
            libraryDownload = 0
            assetDownload = 0

            if let cerr = err as? CError {
                switch cerr {
                    case .networkError(let errorMessage):
                        self.launchStatus = .failed("Network Error: \(errorMessage)")
                    case .encodingError(let errorMessage):
                        self.launchStatus = .failed("Encoding Error: \(errorMessage)")
                    case .decodingError(let errorMessage):
                        self.launchStatus = .failed("Decoding Error: \(errorMessage)")
                    case .filesystemError(let errorMessage):
                        self.launchStatus = .failed("Filesystem Error: \(errorMessage)")
                    case .stateError(let errorMessage):
                        self.launchStatus = .failed("State Error: \(errorMessage)")
                    case .sha1Error(let expected, let found):
                        self.launchStatus = .failed("SHA1 Mismatch: Expected \(expected) but found \(found)")
                    case .unknownVersion(let version):
                        self.launchStatus = .failed("Unknown Version: \(version)")
                    case .unknownError(let errorMessage):
                        self.launchStatus = .failed(errorMessage)
                }
            } else {
                self.launchStatus = .failed(err.localizedDescription)
            }

            return
        }
    }
}
