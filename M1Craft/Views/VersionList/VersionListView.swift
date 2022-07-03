//
//  VersionListView.swift
//  M1Craft
//
//  Created by Ezekiel Elin on 2/23/22.
//

import SwiftUI
import InstallationManager

struct VersionListView: View {
	@EnvironmentObject
	var appState: AppState
	@Binding
	var selectedVersionId: VersionManifest.VersionMetadata.ID?
	var manifest: VersionManifest
	
	var versions: [VersionManifest.VersionTypeMetadataPair] {
		return manifest.versionTypes.sorted(by: { v1, v2 in
			let v1Fav = appState.favoriteVersions.contains(v1.version)
			let v2Fav = appState.favoriteVersions.contains(v2.version)
			if v1Fav && !v2Fav {
				return true
			} else  if v2Fav && !v1Fav {
				return false
			} else {
				switch v1.version {
					case .custom(_):
						switch v2.version {
							case .custom(_):
								return v1.metadata.releaseTime > v2.metadata.releaseTime
							default:
								return false
						}

					default:
						switch v2.version {
							case .custom(_):
								return v1.metadata.releaseTime > v2.metadata.releaseTime
							default:
								return true
						}
				}
			}
		})
	}
	
	init(selectedVersionId: Binding<VersionManifest.VersionMetadata.ID?>, manifest: VersionManifest) {
		self._selectedVersionId = selectedVersionId
		self.manifest = manifest
	}
	
	var body: some View {
		VStack {
			List(self.versions, selection: $selectedVersionId) { versionPair in
				VersionListRowView(
					versionMetadataPair: versionPair,
					favorite: appState.favoriteVersions.contains(versionPair.version),
					selected: selectedVersionId == versionPair.metadata.id
				)
				.environmentObject(appState)
			}
		}
	}
}
