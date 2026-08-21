//
//  PostGridFeedCell.swift
//  Broche
//
//  Created by Jacob Johnson on 12/13/23.
//

import SwiftUI
import LinkPresentation
import Kingfisher
import AVKit
import Firebase

struct PostGridFeedCell: View {
    @ObservedObject var viewModel: FeedCellViewModel
       var autoOpenComments: Bool = false
       @State private var showOptionsSheet = false
       @State private var showSharePostSheet = false
       @State private var selectedOptionsOption: OptionsItemModel?
       @State private var showDetail = false
       @State private var showDeleteConfirmation = false
       @State private var isCaptionExpanded = false
       @State private var showCommentsSheet = false
       @State private var showBookmarkSheet = false
       @State private var isPlaying = true
       @State private var showPlayPauseIcon = false
       @State private var player: AVPlayer?
       @Environment(\.colorScheme) var colorScheme
       
       var showDeleteOption: Bool { return viewModel.post.isCurrentUser }
       var didLike: Bool { return viewModel.post.didLike ?? false }
       var didBookmark: Bool { return viewModel.post.didBookmark ?? false }
       
       private let injectedPlayer: AVPlayer?
       
       init(viewModel: FeedCellViewModel, player: AVPlayer? = nil, autoOpenComments: Bool = false) {   // CHANGED
           self.viewModel = viewModel
           self.injectedPlayer = player
           self.autoOpenComments = autoOpenComments   // NEW
       }
    
    var body: some View {
        ZStack {
            // Post image or video
            if let player = player {
                            VideoPlayerController(player: player)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .onTapGesture(count: 2) {   // CHANGED — was .simultaneousGesture
                                    print("Double tap on video")
                                    handleDoubleTap()
                                }
                                .onTapGesture(count: 1) {   // NEW — only fires if it's NOT part of a double-tap
                                    togglePlayback()
                                }
                            
                            // NEW — brief play/pause icon flash
                if showPlayPauseIcon {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                        .padding(28)
                                        .background(.black.opacity(0.35))
                                        .clipShape(Circle())
                                        .transition(.opacity)
                                        .allowsHitTesting(false)
                                }
                            }
            
            // Overlay UI
            VStack(alignment: .leading) {
                // User profile, username, and location
                HStack {
                    NavigationLink(
                        destination: MapViewForLocation(location: viewModel.post.location),
                        label: {
                            HStack {
                                Image(systemName: "mappin")
                                    .imageScale(.large)
                                    .foregroundColor(.black)
                                    .frame(width: 28, height: 28)
                                    .background(.thinMaterial)
                                    .cornerRadius(10)
                                Text(viewModel.post.location)
                                    .font(.footnote)
                                    .allowsHitTesting(false)
                            }
                        })
                    
                    Spacer()
                        .allowsHitTesting(false)
                    HStack {
                        Text("\(viewModel.post.user?.username ?? "")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .allowsHitTesting(false)
                        
                        if let user = viewModel.post.user {
                            NavigationLink(destination: ProfileView(user: user)) {   // CHANGED
                                CircularProfileImageView(user: user, size: .xSmall)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, 12)
                .padding(.top, 5)
                
                Spacer()
                    .allowsHitTesting(false)
                
                // Action buttons
                HStack(spacing: 16) {
                    VStack(spacing: 16) {
                        Button {
                            showCommentsSheet.toggle()
                        } label: {
                            VStack {
                                Image(systemName: "bubble.left.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .accentColor(.white)
                                    .foregroundColor(.white)
                                Text(viewModel.commentString)
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        Button {
                            selectedOptionsOption = nil
                            showOptionsSheet.toggle()
                        } label: {
                            Image(systemName: "ellipsis")
                                .imageScale(.large)
                                .frame(width: 30, height: 30)
                                .accentColor(.white)
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                        .allowsHitTesting(false)
                    
                    VStack(spacing: 16) {
                        Button {
                            print("like post via button")
                            Task { didLike ? try await viewModel.unlike() : try await viewModel.like() }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(didLike ? .red : .white)
                                NavigationLink(destination: UserListView(config: .likes(viewModel.post.id ?? ""))) {   // CHANGED
                                    Text(viewModel.likeString)
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        
                        Button {
                            print("bookmark post")
                            if didBookmark {
                                Task { try await viewModel.unbookmark() }
                            } else {
                                showBookmarkSheet = true
                            }
                        } label: {
                            Image(systemName: "bookmark.fill")
                                .resizable()
                                .frame(width: 22, height: 28)
                                .accentColor(.white)
                                .foregroundColor(didBookmark ? .cyan : .white)
                        }
                    }
                }
                .padding(.bottom, 15)
                .padding(.horizontal, 10)
                
                // Likes and comments label
                
                
                // Caption
                HStack {
                    Text("\(viewModel.post.caption ?? "")")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .allowsHitTesting(false)
                    Text(viewModel.timestampString)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .allowsHitTesting(false)
                }
                .padding()
                .padding(.top, 1)
            }
        }
        .onAppear {
                    setupPlayerIfNeeded()
                    player?.seek(to: .zero)
                    player?.play()
                    isPlaying = true
                    showPlayPauseIcon = false
                    if autoOpenComments {   // NEW
                        showCommentsSheet = true
                    }
                }
                .onDisappear {
                    player?.pause()
                    player?.seek(to: .zero)
                    if let currentItem = player?.currentItem {
                        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
                    }
                }
        .sheet(isPresented: $showCommentsSheet) {
            CommentsView(post: viewModel.post)
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBookmarkSheet) {
            BookmarkSheet(
                userId: Auth.auth().currentUser?.uid ?? "",
                onSelectCollection: { collection in
                    viewModel.bookmarkPost(collectionId: collection.id ?? "")
                },
                onCreateCollection: { name in
                    viewModel.createCollectionAndBookmark(name: name)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showOptionsSheet) {
            OptionsView(selectedOption: $selectedOptionsOption, showDeleteOption: showDeleteOption, post: viewModel.post)
                .presentationDetents([.height(CGFloat(OptionsItemModel.allCases.count * 56))])
        }
        .onChange(of: selectedOptionsOption) { newValue in
            guard let option = newValue else { return }
            if option == .sharepost {
                showOptionsSheet = false // Dismiss OptionsView
                showSharePostSheet = true // Show SharePostSheetView
                selectedOptionsOption = nil // Reset immediately
            } else if option == .delete {
                Task { try await viewModel.deletePost() }
                selectedOptionsOption = nil
                    
            }
            print("🔔 Selected option: \(option.title)")
        }
        .onChange(of: showSharePostSheet) { newValue in
            print("� Bellamy showSharePostSheet changed: \(newValue)")
        }
        .sheet(isPresented: $showSharePostSheet) {
            SharePostSheetView(post: viewModel.post)
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func setupPlayerIfNeeded() {   // NEW
            guard player == nil else { return }   // already have one — never overwrite it
            
            if let injectedPlayer = injectedPlayer {
                player = injectedPlayer
            } else if let videoUrlString = viewModel.post.videoUrl, let videoUrl = URL(string: videoUrlString) {
                player = AVPlayer(url: videoUrl)
            }
            
            if let player = player {
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: player.currentItem,
                    queue: .main
                ) { _ in
                    player.seek(to: .zero)
                    player.play()
                    isPlaying = true
                }
            }
        }
    
    private func togglePlayback() {
            guard let player = player else { return }
            if isPlaying {
                player.pause()
            } else {
                player.play()
            }
            isPlaying.toggle()
            
            if isPlaying {
                // CHANGED — resuming: hide icon right away, no flash needed since motion is the feedback
                withAnimation(.easeOut(duration: 0.2)) {
                    showPlayPauseIcon = false
                }
            } else {
                // CHANGED — pausing: show play icon and leave it up
                withAnimation(.easeIn(duration: 0.15)) {
                    showPlayPauseIcon = true
                }
            }
        }
    
    private func handleDoubleTap() {
        print("handleDoubleTap called")
        Task {
            do {
                try await viewModel.like()
            } catch {
                print("Error liking post: \(error)")
            }
        }
    }
}
