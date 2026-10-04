//
//  LocationPostPagerView.swift
//  Broche
//
//  Created by Jacob Johnson on 10/1/26.
//

import SwiftUI

struct LocationPostPagerView: View {
    let posts: [Post]
    let startPostId: String
    @StateObject private var playback = FeedPlaybackCoordinator()
    @State private var frames: [String: CGRect] = [:]
    @State private var viewportHeight: CGFloat = 0
    @State private var didScrollToStart = false
    @State private var openedVideoPost: Post?
    @State private var showVideo = false

    init(posts: [Post], startPost: Post) {
        self.posts = posts
        self.startPostId = startPost.id ?? ""
    }

    var body: some View {
        GeometryReader { outer in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(posts) { post in
                            PagerCell(post: post, playback: playback) { tapped in
                                openedVideoPost = tapped
                                showVideo = true
                            }
                            .id(post.id ?? "")
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: CellFramesKey.self,
                                        value: [post.id ?? "": geo.frame(in: .named("feed"))]
                                    )
                                }
                            )
                            Divider()
                        }
                    }
                }
                .coordinateSpace(name: "feed")
                .onPreferenceChange(CellFramesKey.self) { newFrames in
                    frames = newFrames
                    viewportHeight = outer.size.height
                    updateActiveVideo(frames: newFrames, viewportHeight: outer.size.height)
                }
                .onAppear {
                    if !didScrollToStart {
                        didScrollToStart = true
                        DispatchQueue.main.async { proxy.scrollTo(startPostId, anchor: .top) }
                    } else {
                        // coming back from the full-screen video: restart the right inline video
                        updateActiveVideo(frames: frames, viewportHeight: viewportHeight)
                    }
                }
            }
        }
        .onDisappear { playback.deactivate() }   // also pauses the feed player while the full-screen video is up
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showVideo) {
            if let post = openedVideoPost {
                PostGridFeedCell(viewModel: FeedCellViewModel(post: post))
            }
        }
    }

    private func updateActiveVideo(frames: [String: CGRect], viewportHeight: CGFloat) {
        var best: (post: Post, visible: CGFloat)?
        for post in posts {
            guard let urlString = post.videoUrl, !urlString.isEmpty,
                  let frame = frames[post.id ?? ""], frame.height > 0 else { continue }
            let visibleHeight = max(0, min(frame.maxY, viewportHeight) - max(frame.minY, 0))
            let fraction = visibleHeight / min(frame.height, viewportHeight)
            if fraction > 0.6, fraction > (best?.visible ?? 0) {
                best = (post, fraction)
            }
        }
        if let best, let id = best.post.id, let url = URL(string: best.post.videoUrl ?? "") {
            playback.activate(postId: id, url: url)
        } else {
            playback.deactivate()
        }
    }
}

private struct CellFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

private struct PagerCell: View {
    @StateObject private var viewModel: FeedCellViewModel
    @ObservedObject var playback: FeedPlaybackCoordinator
    var onOpenVideo: (Post) -> Void
    private let post: Post

    init(post: Post, playback: FeedPlaybackCoordinator, onOpenVideo: @escaping (Post) -> Void) {
        self.post = post
        self.playback = playback
        self.onOpenVideo = onOpenVideo
        _viewModel = StateObject(wrappedValue: FeedCellViewModel(post: post))
    }

    var body: some View {
        PostCard(viewModel: viewModel) {
            if let videoUrl = post.videoUrl, !videoUrl.isEmpty {
                InlineVideoView(
                    post: post,
                    playback: playback,
                    onDoubleTap: { Task { try? await viewModel.like() } },
                    onOpen: { onOpenVideo(post) }
                )
            } else if let imageUrl = post.imageUrl {
                ZoomableImageView(url: imageUrl)
                    .simultaneousGesture(TapGesture(count: 2).onEnded {
                        Task { try? await viewModel.like() }
                    })
            }
        }
    }
}
