//
//  NearbyMediaView.swift
//  Broche
//
//  Created by Jacob Johnson on 10/9/26.
//

import SwiftUI
import Photos
import CoreLocation

struct NearbyMediaPickerView: View {
    let center: CLLocationCoordinate2D
    let placeName: String
    var onPickedFromAll: () -> Void = {}
    var onCancel: () -> Void = {}
    var onPicked: (PHAsset) -> Void
   

    @Environment(\.dismiss) private var dismiss
    @StateObject private var loader = NearbyMediaLoader()
    @State private var radiusMiles: Double = 3   // was radiusKm = 5

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Within \(Int(radiusMiles)) mi")
                        .font(.footnote.bold())
                    Slider(value: $radiusMiles, in: 1...30, step: 1) { editing in
                        if !editing { reload() }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                if loader.isLoading {
                    ProgressView().frame(maxHeight: .infinity)
                } else if loader.assets.isEmpty {
                    VStack(spacing: 12) {
                        Text("No photos or videos found near \(placeName)")
                            .foregroundStyle(.secondary)
                        Button("Browse all photos") {
                            onPickedFromAll()
                            dismiss()
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(loader.assets, id: \.localIdentifier) { asset in
                                AssetThumbnail(asset: asset, isSelected: false)
                                    .onTapGesture {
                                        onPicked(asset)
                                        dismiss()
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle(placeName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("All photos") {
                        onPickedFromAll()
                        dismiss()
                    }
                }
            }
            .onAppear { reload() }
        }
    }

    private func reload() {
        loader.load(near: center, radiusMeters: radiusMiles * 1609.344)
    }
}

// MARK: - Thumbnail
struct AssetThumbnail: View {
    let asset: PHAsset
    let isSelected: Bool
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                if let image {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Color(.secondarySystemBackground)
                }
                if asset.mediaType == .video {
                    Image(systemName: "video.fill")
                        .font(.caption2).foregroundStyle(.white)
                        .padding(4)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
                if isSelected {
                    Color.blue.opacity(0.3)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white, .blue)
                        .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            let opts = PHImageRequestOptions()
            opts.deliveryMode = .opportunistic
            opts.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFill,
                options: opts
            ) { img, _ in
                if let img { self.image = img }
            }
        }
    }
}
