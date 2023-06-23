//
//  VideoThumbnail.swift
//  Broche
//
//  Created by Jacob Johnson on 6/22/23.
//

import SwiftUI
import AVKit

struct VideoThumbnail: View {
    let url: URL
    @State private var thumbnailImage: UIImage? = nil
    
    var body: some View {
        if let image = thumbnailImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color.gray
                .onAppear(perform: generateThumbnailImage)
        }
    }
    
    private func generateThumbnailImage() {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [self] _, image, _, _, _ in
            if let image = image {
                DispatchQueue.main.async {
                    thumbnailImage = UIImage(cgImage: image)
                }
            }
        }
    }
}



