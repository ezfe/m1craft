//
//  VersionListRowView.swift
//  M1Craft
//
//  Created by Ezekiel Elin on 2/23/22.
//

import SwiftUI
import InstallationManager

struct VersionListRowView: View {
    let version: VersionManifest.VersionType
    let metadata: VersionManifest.VersionMetadata
    let selected: Bool
    let appState: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(verbatim: "\(metadata.id)")
                    .font(.body)
                Text(verbatim: metadata.releaseTime.formatted())
                    .font(.caption)
            }
            Spacer()
            switch appState.launchStatus {
                case .idle, .failed(_):
                    playControl()
                case .starting:
                    Button("Starting...", action: { () in })
                        .buttonStyle(AppStoreButtonStyle(primary: true, highlighted: selected))
                        .disabled(true)
                case .running:
                    Button("Running...", action: { () in })
                        .buttonStyle(AppStoreButtonStyle(primary: true, highlighted: selected))
                        .disabled(true)
            }
        }
        .contextMenu {
            Button(action: self.playAction) {
                Label("Play", systemImage: "play.circle")
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
            await appState.runGame(metadata: self.metadata)
        }
    }
}

struct VersionListRowView_Previews: PreviewProvider {
    static var previews: some View {
        VersionListRowView(
            version: .custom("1.19.1"),
            metadata: .init(id: "1.19.1", type: "snapshot", time: Date(), releaseTime: Date(), url: "https://mojang.com/version1.json", sha1: "123sha456"),
            selected: false,
            appState: AppState()
        )
        VersionListRowView(
            version: .release,
            metadata: .init(id: "1.19.2", type: "snapshot", time: Date(), releaseTime: Date(), url: "https://mojang.com/version2.json", sha1: "123sha456"),
            selected: true,
            appState: AppState()
        )
    }
}
