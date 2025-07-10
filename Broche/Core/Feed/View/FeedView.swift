//
//  FeedView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import AVKit
import FirebaseAuth

struct FeedView: View {
    @StateObject var viewModel = FeedViewModel()
    @StateObject var conversationsViewModel = ConversationsViewModel()
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
                                    playInitialVideoIfNecessary(post: post)
                                    if post == viewModel.posts.last {
                                        Task {
                                            try await viewModel.fetchMorePosts()
                                            scrollView.scrollTo(viewModel.lastDocument, anchor: .bottom)
                                        }
                                    }
                                }
                        }
                    }
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
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: "paperplane")
                                            .imageScale(.large)
                                            .scaledToFit()
                                        if conversationsViewModel.recentMessages.contains(where: { !$0.isRead && $0.fromId != Auth.auth().currentUser?.uid }) {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 8, height: 8)
                                                .offset(x: 6, y: -6)
                                        }
                                    }
                                })
                        }
                    }
                    .navigationDestination(for: User.self) { user in
                        ProfileView(user: user)
                    }
                }
                .onAppear {
                    player.play()
                    conversationsViewModel.loadData()
                    print("🔔 FeedView onAppear - checking for unread messages")
                }
                .onDisappear { player.pause() }
                .scrollPosition(id: $scrollPosition)
                .scrollTargetBehavior(.paging)
                .onChange(of: scrollPosition) { oldValue, newValue in
                    playVideoOnChangeOfScrollPosition(postId: newValue)
                }
                .refreshable {
                    Task {
                        viewModel.posts.removeAll()
                        try await viewModel.fetchPosts()
                    }
                }
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
        playerLooper?.disableLooping()
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
    }
}



#Preview {
        FeedView()
}
