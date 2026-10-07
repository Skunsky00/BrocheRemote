//
//  CameraRollImportView.swift
//  Broche
//
//  Created by Jacob Johnson on 10/3/26.
//

import SwiftUI
import Photos

struct CameraRollImportView: View {
    @StateObject private var viewModel: CameraRollImportViewModel
    @Environment(\.dismiss) private var dismiss
    var onFinished: (Int) -> Void

    @State private var renamingID: UUID?
    @State private var renameText = ""

    init(user: User, fullRescan: Bool = false, onFinished: @escaping (Int) -> Void) {
        _viewModel = StateObject(wrappedValue: CameraRollImportViewModel(userId: user.id, fullRescan: fullRescan))
        self.onFinished = onFinished
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isScanning {
                    VStack(spacing: 12) {
                        ProgressView()
                        if let p = viewModel.namingProgress {
                            Text("Naming places \(p.done)/\(p.total)…")
                                .font(.subheadline).foregroundStyle(.secondary)
                        } else {
                            Text("Scanning your photos…")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.scanComplete && viewModel.suggestions.isEmpty {
                    ContentUnavailableView("No new places found", systemImage: "photo.on.rectangle")
                } else {
                    List {
                        if viewModel.isNaming, let p = viewModel.namingProgress {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Naming places \(p.done)/\(p.total)…")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        ForEach($viewModel.suggestions) { $suggestion in
                            SuggestionRow(suggestion: $suggestion) {
                                renameText = suggestion.cityName ?? ""
                                renamingID = suggestion.id
                            }
                        }
                    }
                }
            }
            .navigationTitle("Build Your Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .principal) { EmptyView() }
                ToolbarItem(placement: .topBarTrailing) {
                    let count = viewModel.suggestions.filter { $0.isSelected }.count
                    Button {
                        Task {
                            let saved = await viewModel.saveSelected()
                            onFinished(saved)
                            dismiss()
                        }
                    } label: {
                        if viewModel.isSaving { ProgressView() } else { Text("Add \(count)") }
                    }
                    .disabled(count == 0 || viewModel.isSaving || viewModel.isNaming)
                }
                ToolbarItem(placement: .bottomBar) {
                    if viewModel.scanComplete && !viewModel.suggestions.isEmpty {
                        HStack {
                            Button("Select all") { viewModel.setAll(selected: true) }
                            Spacer()
                            Button("Combine by city") { viewModel.combineByCity() }
                                .disabled(viewModel.isNaming)
                            Spacer()
                            Button("Select none") { viewModel.setAll(selected: false) }
                        }
                    }
                }
            }
            .alert("Rename place", isPresented: Binding(
                get: { renamingID != nil },
                set: { if !$0 { renamingID = nil } })
            ) {
                TextField("City name", text: $renameText)
                Button("Save") {
                    if let id = renamingID { viewModel.rename(id, to: renameText) }
                    renamingID = nil
                }
                Button("Cancel", role: .cancel) { renamingID = nil }
            }
            .task {
                if viewModel.suggestions.isEmpty { await viewModel.scan() }
            }
        }
    }
}

private struct SuggestionRow: View {
    @Binding var suggestion: PlaceSuggestion
    var onEdit: () -> Void
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail { Image(uiImage: thumbnail).resizable().scaledToFill() }
                else { Color(.secondarySystemBackground) }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.cityName ?? (suggestion.namingFailed ? "Unknown place, tap ✎ to name" : "Naming…"))
                    .font(.subheadline.bold())
                    .foregroundStyle(suggestion.namingFailed ? .orange : .primary)
                Text("\(suggestion.assetCount) photo\(suggestion.assetCount == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil").foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)

            Image(systemName: suggestion.isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(suggestion.isSelected ? Color.theme.brocheIndigo : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { suggestion.isSelected.toggle() }
        .task {
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            PHImageManager.default().requestImage(
                for: suggestion.thumbnailAsset,
                targetSize: CGSize(width: 112, height: 112),
                contentMode: .aspectFill, options: options
            ) { img, _ in thumbnail = img }
        }
    }
}
