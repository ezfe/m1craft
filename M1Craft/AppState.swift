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
	case starting(VersionManifest.VersionType, String) // Version, Message
	case running(VersionManifest.VersionType, Process) // Version, Process
	case failed(VersionManifest.VersionType, String) // Version, Message
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
	
	@AppStorage("azure_refresh_token")
	var azureRefreshToken: String = ""
	@AppStorage("favorite-versions")
	var favoriteVersions: [VersionManifest.VersionType] = [.release]
	@AppStorage("selected-memory-allocation")
	var selectedMemoryAllocation: Int = 3
	
	@Published
	var credentials: SignInResult? = nil
	
	// Used for exporting versions
	@State
	var alertPresented = false
	@State
	var alertTitle = ""
	@State
	var alertMessage: String? = nil
	
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
		
		var preflightUrl = preflightUrl
		let queryItem = URLQueryItem(name: "app_version", value: appVersion)
		if #available(macOS 13.0, *) {
			preflightUrl.append(queryItems: [queryItem])
		} else {
			var components = URLComponents(string: preflightUrl.absoluteString)!
			components.queryItems = [queryItem]
			preflightUrl = components.url!
		}
		
		let response = try? await retrieveData(from: preflightUrl)
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
	
	func runGame(version: VersionManifest.VersionTypeMetadataPair) async {
		let versionType = version.version
		let metadata = version.metadata

		print("Running \(metadata.id)")
		self.launchStatus = .starting(versionType, "")

		guard let credentials = credentials else {
			print("Not logged in")
			self.launchStatus = .failed(versionType, "Not logged in")
			return
		}
				
		do {
			self.launchStatus = .starting(versionType, "Initializing")
			let installationManager = try InstallationManager()
			
			print("Patching")
			self.launchStatus = .starting(versionType, "Patching for ARM")
			let patchInfo = try await VersionPatch.download(for: metadata.id)
			let package = try await metadata.package(with: patchInfo)
			guard package.minimumLauncherVersion >= 21 else {
				self.launchStatus = .failed(versionType, "Unfortunately, This utility does not work with versions prior to 1.13")
				return
			}
			
			print("Starting Java Download")
			self.launchStatus = .starting(versionType, "Starting Java Download")
							
			self.javaDownload = 0.10
			
			let clientJar = try await installationManager.downloadJar(for: package)
			self.javaDownload = 0.4

			let _ = try await installationManager.downloadJava(for: package)
			self.javaDownload = 1
			
			print("Starting Asset Download")
			self.launchStatus = .starting(versionType, "Starting Asset Download")
			try await installationManager.downloadAssets(for: package, with: patchInfo) { [weak self] progress in
				self?.assetDownload = progress
			}
			
			print("Starting Library Download")
			self.launchStatus = .starting(versionType, "Starting Library Download")
			let _ = try await installationManager.downloadLibraries(for: package) { [weak self] progress in
				self?.libraryDownload = progress
			}
			
			self.launchStatus = .starting(versionType, "Installing Natives")
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
					proc.terminationHandler = { proc in
						DispatchQueue.main.async {
							self.launchStatus = .idle
						}
					}

//					let pipe = Pipe()
//					proc.standardOutput = pipe
					
//					print(javaExec.absoluteString)
//					print(args.joined(separator: " "))
//					print(installationManager.baseDirectory.absoluteString)
					
					self.launchStatus = .starting(versionType, "Launching game")
					proc.launch()

					self.launchStatus = .running(versionType, proc)
					self.javaDownload = 0
					self.libraryDownload = 0
					self.assetDownload = 0
				case .failure(let error):
					self.launchStatus = .failed(versionType, error.localizedDescription)
					return
			}
		} catch let err {
			javaDownload = 0
			libraryDownload = 0
			assetDownload = 0

			if let cerr = err as? CError {
				switch cerr {
					case .networkError(let errorMessage):
						self.launchStatus = .failed(versionType, "Network Error: \(errorMessage)")
					case .encodingError(let errorMessage):
						self.launchStatus = .failed(versionType, "Encoding Error: \(errorMessage)")
					case .decodingError(let errorMessage):
						self.launchStatus = .failed(versionType, "Decoding Error: \(errorMessage)")
					case .filesystemError(let errorMessage):
						self.launchStatus = .failed(versionType, "Filesystem Error: \(errorMessage)")
					case .stateError(let errorMessage):
						self.launchStatus = .failed(versionType, "State Error: \(errorMessage)")
					case .sha1Error(let expected, let found):
						self.launchStatus = .failed(versionType, "SHA1 Mismatch: Expected \(expected) but found \(found)")
					case .unknownVersion(let version):
						self.launchStatus = .failed(versionType, "Unknown Version: \(version)")
					case .unknownError(let errorMessage):
						self.launchStatus = .failed(versionType, errorMessage)
				}
			} else {
				self.launchStatus = .failed(versionType, err.localizedDescription)
			}

			return
		}
	}
}
