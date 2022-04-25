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
    
    init(selectedVersionId: Binding<VersionManifest.VersionMetadata.ID?>, manifest: VersionManifest) {
        self._selectedVersionId = selectedVersionId
        self.manifest = manifest
    }
    
    var body: some View {
        VStack {
            if case .success(let manifest) = appState.initializationStatus {
                List(manifest.versionTypes, selection: $selectedVersionId) { versionPair in
                    VersionListRowView(
                        version: versionPair.version,
                        metadata: versionPair.metadata,
                        selected: selectedVersionId == versionPair.metadata.id
                    )
                    .environmentObject(appState)
                }
            } else {
                EmptyView()
            }
        }
    }
}
