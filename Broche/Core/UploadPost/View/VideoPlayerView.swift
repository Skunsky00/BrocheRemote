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
                    VideoPlayerController(videoURL: videoURL)
                        .aspectRatio(16/9, contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width * 16/9)
                        .clipped()
                        .onAppear {
                            // Play the video only if this is the focused video
                            
                                VideoPlayerController.play()
                            }
                        
                        .onDisappear {
                            // Pause the video only if this is the focused video
                            
                                VideoPlayerController.pause()
                            
                        }
        }
    }
}

struct VideoPlayerController: UIViewControllerRepresentable {
    let videoURL: URL
    static private var player: AVPlayer?

    static func play() {
        player?.play()
    }

    static func pause() {
        player?.pause()
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerController>) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.updatesNowPlayingInfoCenter = false
        controller.player = AVPlayer(url: videoURL)
        VideoPlayerController.player = controller.player // Store the player statically
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerController>) {
        // In case the videoURL is changed, update the player with the new URL
        if let currentPlayer = uiViewController.player, currentPlayer.currentItem?.asset != AVAsset(url: videoURL) {
            currentPlayer.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
            VideoPlayerController.player = currentPlayer // Update the static player with the new player instance
        }
    }
}
