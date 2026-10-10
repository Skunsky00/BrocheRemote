//
//  NearbyMediaLoader.swift
//  Broche
//
//  Created by Jacob Johnson on 10/9/26.
//

import Foundation
import Photos
import CoreLocation

// MARK: - Loader
@MainActor
final class NearbyMediaLoader: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var isLoading = false

    func load(near center: CLLocationCoordinate2D, radiusMeters: Double) {
        isLoading = true
        let target = CLLocation(latitude: center.latitude, longitude: center.longitude)

        Task.detached(priority: .userInitiated) {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.predicate = NSPredicate(
                format: "mediaType == %d OR (mediaType == %d AND duration <= %f)",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaType.video.rawValue,
                UploadLimits.maxVideoSeconds
            )
            let result = PHAsset.fetchAssets(with: options)

            var matches: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in
                guard let loc = asset.location else { return }
                if loc.distance(from: target) <= radiusMeters {
                    matches.append(asset)
                }
            }
            await MainActor.run {
                self.assets = matches
                self.isLoading = false
            }
        }
    }
}


enum UploadLimits {
    static let maxVideoSeconds: Double = 180   // 3 minutes
    
}

