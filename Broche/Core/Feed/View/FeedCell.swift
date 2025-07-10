//
//  FeedCell.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import AVKit
import Kingfisher
import Firebase

struct FeedCell: View {
    @ObservedObject var viewModel: FeedCellViewModel
    @State private var showOptionsSheet = false
    @State private var showSharePostSheet = false
    @State private var selectedOptionsOption: OptionsItemModel?
    @State private var showDetail = false
    @State private var showDeleteConfirmation = false
    @State private var isCaptionExpanded = false
    @State private var showCommentsSheet = false
    @State private var showBookmarkSheet = false
    @Environment(\.colorScheme) var colorScheme
    
    var showDeleteOption: Bool { return viewModel.post.isCurrentUser }
    var didLike: Bool { return viewModel.post.didLike ?? false }
    var didBookmark: Bool { return viewModel.post.didBookmark ?? false }
    
    var player: AVPlayer?
    
    init(viewModel: FeedCellViewModel, player: AVPlayer? = nil) {
        self.viewModel = viewModel
        self.player = player
    }
    
    var body: some View {
        ZStack {
            // Post image or video
            if let imageUrl = viewModel.post.imageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.1)
                    .clipped()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Single tap on image")
                    }
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded {
                                print("Double tap on image")
                                handleDoubleTap()
                            }
                    )
            } else if let player = player {
                VideoPlayerController(player: player)
                    .containerRelativeFrame([.horizontal, .vertical])
                    .onTapGesture {
                        print("Single tap on video")
                        switch player.timeControlStatus {
                        case .paused:
                            player.play()
                        case .waitingToPlayAtSpecifiedRate, .playing:
                            player.pause()
                        default:
                            break
                        }
                    }
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded {
                                print("Double tap on video")
                                handleDoubleTap()
                            }
                    )
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
                    
                    if let user = viewModel.post.user {
                        NavigationLink(value: user) {
                            CircularProfileImageView(user: user, size: .xSmall)
                        }
                    }
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
                                NavigationLink(value: SearchViewModelConfig.likes(viewModel.post.id ?? "")) {
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
                HStack {
                    Text(viewModel.post.label ?? "")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .allowsHitTesting(false)
                    
                    Spacer()
                        .allowsHitTesting(false)
                    
                    Text("\(viewModel.post.user?.username ?? "")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .allowsHitTesting(false)
                }
                .padding(.horizontal, 16)
                
                // Caption
                HStack {
                    Text("\(viewModel.post.caption)")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .allowsHitTesting(false)
                }
                .padding()
                .padding(.top, 1)
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
            } else if option == .pinToBroche {
                showDetail.toggle()
                selectedOptionsOption = nil
            }
            print("🔔 Selected option: \(option.title)")
        }
        .onChange(of: showSharePostSheet) { newValue in
            print("🔔 showSharePostSheet changed: \(newValue)")
        }
        .navigationDestination(for: SearchViewModelConfig.self) { config in
            UserListView(config: config)
        }
        .sheet(isPresented: $showSharePostSheet) {
            SharePostSheetView(post: viewModel.post)
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
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
