//
//  FeedView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import AVKit

struct FeedView: View {
    @StateObject var viewModel = FeedViewModel()
    @State private var scrollPosition: String?
    @State private var player = AVQueuePlayer()
    @State private var playerLooper: AVPlayerLooper?
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.posts) { post in
                            FeedCell(viewModel: FeedCellViewModel(post: post), player: player)
                                .id(post.id ?? "")
                                .onAppear {
                                    // Load more posts when the last post is about to appear
                                    playInitialVideoIfNecessary(post: post)
                                    if post == viewModel.posts.last {
                                        Task {
                                            try await viewModel.fetchMorePosts()
                                            // Scroll to the newly loaded posts
                                            scrollView.scrollTo(viewModel.lastDocument, anchor: .bottom)
                                            
                                        }
                                    }
                                }
                        }
                    }
                    .navigationTitle("Feed")
                    .navigationBarTitleDisplayMode(.inline)
                    .scrollTargetLayout()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("Broche")
                                .font(.title)
                                .fontWeight(.bold)
                                .frame(width: 100, height: 32)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(
                                destination: ConversationsView(),
                                label: {
                                    Image(systemName: "paperplane")
                                        .imageScale(.large)
                                        .scaledToFit()
                                })
                        }
                    }
                    .navigationDestination(for: User.self) { user in
                        ProfileView(user: user)
                    }
                }
                .onAppear { player.play() }
                .scrollPosition(id: $scrollPosition)
                .scrollTargetBehavior(.paging)
                .onChange(of: scrollPosition) { oldValue, newValue in
                        playVideoOnChangeOfScrollPosition(postId: newValue)
                                }
                .refreshable {
                    Task {
                        // Clear existing posts before fetching new ones
                        viewModel.posts.removeAll()
                        try await viewModel.fetchPosts()
                    }
                }
                // weird bug but you have to have 1 px of padding for it to work dont know why.
                .padding(.bottom, 1)
            }
        }
    }
    
    func playInitialVideoIfNecessary(post: Post) {
            guard
                scrollPosition == nil,
                player.items().isEmpty else { return }

            let playerItem = AVPlayerItem(url: URL(string: post.videoUrl!)!)
            player.replaceCurrentItem(with: playerItem)
            addLooper(to: playerItem)
        }

    func playVideoOnChangeOfScrollPosition(postId: String?) {
            guard let currentPost = viewModel.posts.first(where: { $0.id == postId }) else { return }

            if player.items().isEmpty || player.currentItem?.asset != AVURLAsset(url: URL(string: currentPost.videoUrl!)!) {
                player.removeAllItems()
                let playerItem = AVPlayerItem(url: URL(string: currentPost.videoUrl!)!)
                player.replaceCurrentItem(with: playerItem)
                addLooper(to: playerItem)
            }
        }

    func addLooper(to playerItem: AVPlayerItem) {
           // Remove existing looper before adding a new one
           playerLooper?.disableLooping()
           playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
       }
}



#Preview {
        FeedView()
}
