//
//  VideoPlayerView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/22/23.
//

import AVKit
import SwiftUI



struct VideoPlayerView: View {
    let videoURL: URL

    var body: some View {
            GeometryReader { geometry in
                VideoPlayer(player: AVPlayer(url: videoURL)) {
                    // Video overlay view
                    VStack {
                        Spacer()
                        
                        // Add any additional overlay views here
                        
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.width * 1.33)
                .edgesIgnoringSafeArea(.all)
            }
        }
    }


struct VideoPlayerController: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerController>) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = true
        controller.updatesNowPlayingInfoCenter = false
        controller.player?.allowsExternalPlayback = false
        controller.videoGravity = .resizeAspectFill
        controller.view.contentMode = .scaleAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerController>) {
    }
}
