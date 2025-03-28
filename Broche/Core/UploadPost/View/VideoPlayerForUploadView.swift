//
//  VideoPlayerForUploadView.swift
//  Broche
//
//  Created by Jacob Johnson on 7/31/23.
//

import SwiftUI
import AVKit

struct VideoPlayerForUploadView: View {
    let videoURL: URL
    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(9/16, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }

struct VideoPlayerForController: UIViewControllerRepresentable {
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerForController>) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = true
        controller.updatesNowPlayingInfoCenter = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerForController>) {
    }
}


