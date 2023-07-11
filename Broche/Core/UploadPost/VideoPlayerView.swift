//
//  VideoPlayerView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/22/23.
//

import AVKit
import SwiftUI



//struct VideoPlayerView: View {
//    let url: String
//    @ObservedObject var playerManager: AVPlayerManager
//
//    var body: some View {
//        VideoPlayer(player: playerManager.player)
//            .onAppear {
//                playerManager.play(url: url)
//            }
//            .onDisappear {
//                playerManager.pause()
//            }
//    }
//}
//
//
//class AVPlayerManager: ObservableObject {
//    @Published var player: AVPlayer
//
//    init() {
//        player = AVPlayer()
//    }
//
//    func play(url: String) {
//        guard let videoUrl = URL(string: url) else {
//            return
//        }
//
//        player.replaceCurrentItem(with: AVPlayerItem(url: videoUrl))
//        player.actionAtItemEnd = .none
//        player.play()
//
//        NotificationCenter.default.addObserver(
//            forName: .AVPlayerItemDidPlayToEndTime,
//            object: player.currentItem,
//            queue: nil
//        ) { [weak self] _ in
//            self?.player.seek(to: .zero)
//            self?.player.play()
//        }
//    }
//
//    func pause() {
//        player.pause()
//    }
//}

