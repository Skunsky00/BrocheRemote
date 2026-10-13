//
//  LoopingPlayerViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 10/12/26.
//

import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class LoopingPlayerViewModel: ObservableObject {
    @Published var isPlaying = true
    @Published var isMuted = false

    let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private var loadedURL: URL?

    func load(url: URL) {
        guard url != loadedURL else { return }
        loadedURL = url
        looper?.disableLooping()
        player.removeAllItems()
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        player.isMuted = isMuted
        play()
    }

    func play() { player.play(); isPlaying = true }
    func pause() { player.pause(); isPlaying = false }
    func togglePlay() { isPlaying ? pause() : play() }

    func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
    }

    func teardown() {
        player.pause()
        looper?.disableLooping()
        looper = nil
        loadedURL = nil
        player.removeAllItems()
    }
}

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

final class PlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
