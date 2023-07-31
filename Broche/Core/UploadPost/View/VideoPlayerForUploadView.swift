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
        GeometryReader { geometry in
            VideoPlayer(player: AVPlayer(url: videoURL)) {
            }
            .frame(width: geometry.size.width, height: geometry.size.width * 1.33)
            .edgesIgnoringSafeArea(.all)
        }
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


