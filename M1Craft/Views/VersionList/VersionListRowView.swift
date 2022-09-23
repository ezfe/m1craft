//
//  VersionListRowView.swift
//  M1Craft
//
//  Created by Ezekiel Elin on 2/23/22.
//

import SwiftUI
import InstallationManager

struct VersionListRowView: View {
	let versionMetadataPair: VersionManifest.VersionTypeMetadataPair
	var version: VersionManifest.VersionType { versionMetadataPair.version }
	var metadata: VersionManifest.VersionMetadata { versionMetadataPair.metadata }
	let favorite: Bool
	let selected: Bool
	@EnvironmentObject
	var appState: AppState
	
	var body: some View {
		HStack {
			Button {
				if favorite {
					appState.favoriteVersions.removeAll(where: { $0 == version })
				} else {
					appState.favoriteVersions.append(version)
				}
			} label: {
				if favorite {
					Image(systemName: "star.fill")
						.foregroundColor(.yellow)
				} else {
					Image(systemName: "star")
				}
			}
				.buttonStyle(.borderless)
			VStack(alignment: .leading) {
				switch version {
					case .release:
						Text(verbatim: "Latest Release (\(metadata.id))")
							.font(.body)
					case .snapshot:
						Text(verbatim: "Latest Snapshot (\(metadata.id))")
							.font(.body)
					case .custom(_):
						Text(verbatim: "\(metadata.id)")
							.font(.body)
				}
				Text(verbatim: metadata.releaseTime.formatted())
					.font(.caption)
			}
			Spacer()
			switch appState.launchStatus {
				case .idle:
					playControl()
				case .failed(let version, let message):
					if version == self.version {
						Text(message)
					}
					playControl()
				case .starting(let version, let message):
					if version == self.version {
						Text(message)
						Button("Starting...", action: { () in })
							.buttonStyle(AppStoreButtonStyle(primary: true, highlighted: selected))
							.disabled(true)
					} else {
						EmptyView()
					}
				case .running(let version, let process):
					if version == self.version {
						Button("Running...", action: { () in })
							.buttonStyle(AppStoreButtonStyle(primary: true, highlighted: selected))
							.disabled(true)
						Button {
							process.terminate()
						} label: {
							Label("Stop", systemImage: "xmark.circle")
						}
						.buttonStyle(AppStoreButtonStyle(primary: true, highlighted: selected))

					} else {
						EmptyView()
					}
			}
		}
		.contextMenu {
			Button(action: self.playAction) {
				Label("Play", systemImage: "play.circle")
			}
			if favorite {
				Button() {
					appState.favoriteVersions.removeAll(where: { $0 == version })
				} label: {
					Label("Remove Favorite", systemImage: "star.slash")
				}
			} else {
				Button() {
					appState.favoriteVersions.append(version)
				} label: {
					Label("Add Favorite", systemImage: "star")
				}
			}
			
			Divider()
			
			Button("Export modified version JSON...") {
				let savePanel = NSSavePanel()
				savePanel.allowedContentTypes = [.json]
				savePanel.canCreateDirectories = true
				savePanel.isExtensionHidden = false
				savePanel.allowsOtherFileTypes = false
				savePanel.title = "Save Version JSON"
				savePanel.directoryURL = appState.minecraftDirectory?.appendingPathComponent("versions")
				savePanel.nameFieldLabel = "File name:"
				
				let response = savePanel.runModal()
				
				appState.alertTitle = "Preparing JSON..."
				appState.alertPresented = true
				
				if let url = savePanel.url, response == .OK {
					Task {
						do {
							let patchInfo = try await VersionPatch.download(for: metadata.id)
							let package = try await metadata.package(with: patchInfo)

							let encoder = JSONEncoder()
							encoder.dateEncodingStrategy = .iso8601
							let data = try encoder.encode(package)

							try data.write(to: url)
							print("Saved json...")
							
							appState.alertTitle = "Saved JSON"
						} catch let err {
							appState.alertTitle = "Failed to save JSON"
							appState.alertMessage = err.localizedDescription
						}
					}
				} else {
					appState.alertPresented = false
				}
			}

		}
	}
	
	@ViewBuilder
	private func playControl() -> some View {
		Button("Play", action: self.playAction)
			.buttonStyle(AppStoreButtonStyle(primary: true, highlighted: selected))
			.help("Play \(metadata.id)")
	}
	
	func playAction() {
		Task {
			await appState.runGame(version: versionMetadataPair)
		}
	}
}

/*
struct VersionListRowView_Previews: PreviewProvider {
	static var previews: some View {
		VersionListRowView(
			version: .custom("1.19.1"),
			metadata: .init(id: "1.19.1", type: "snapshot", time: Date(), releaseTime: Date(), url: "https://mojang.com/version1.json", sha1: "123sha456"),
			favorite: true,
			selected: false
		)
		VersionListRowView(
			version: .release,
			metadata: .init(id: "1.19.2", type: "snapshot", time: Date(), releaseTime: Date(), url: "https://mojang.com/version2.json", sha1: "123sha456"),
			favorite: false,
			selected: true
		)
	}
}
*/
