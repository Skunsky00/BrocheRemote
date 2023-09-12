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
    @State private var isPlaying = false

    var body: some View {
        GeometryReader { geometry in
            VideoPlayerController(videoURL: videoURL, isPlaying: $isPlaying)
                .frame(width: geometry.size.width, height: geometry.size.width * 16/9)
                .clipped()
                .onTapGesture {
                    isPlaying.toggle()
                }
        }
    }
}

struct VideoPlayerController: UIViewControllerRepresentable {
    let videoURL: URL
    @Binding var isPlaying: Bool
    private let playerController = AVPlayerViewController()
    private var player: AVPlayer? {
        playerController.player
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerController>) -> AVPlayerViewController {
        playerController.player = AVPlayer(url: videoURL)
        playerController.showsPlaybackControls = false
        playerController.updatesNowPlayingInfoCenter = false
        return playerController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerController>) {
        if isPlaying {
            player?.play()
        } else {
            player?.pause()
        }
    }
}

