//
//  PostCard.swift
//  Broche
//
//  Created by Jacob Johnson on 10/3/26.
//

import SwiftUI
import Kingfisher
import FirebaseAuth

struct PostCard<Media: View>: View {
    @ObservedObject var viewModel: FeedCellViewModel
    var autoOpenComments: Bool = false
    @ViewBuilder var media: () -> Media

    @State private var showOptionsSheet = false
    @State private var showSharePostSheet = false
    @State private var selectedOptionsOption: OptionsItemModel?
    @State private var showCommentsSheet = false
    @State private var showBookmarkSheet = false
    @Environment(\.dismiss) var dismiss

    var showDeleteOption: Bool { viewModel.post.isCurrentUser }
    var didLike: Bool { viewModel.post.didLike ?? false }
    var didBookmark: Bool { viewModel.post.didBookmark ?? false }

    private var likeCountText: String {
        switch viewModel.post.likes {
        case 0: return "0 likes"
        case 1: return "1 like"
        default: return "\(viewModel.post.likes) likes"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                NavigationLink(destination: MapViewForLocation(location: viewModel.post.location)) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                        Text(viewModel.post.location)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.primary)
                }
                Spacer()
                if let user = viewModel.post.user {
                    NavigationLink(destination: ProfileView(user: user)) {
                        HStack(spacing: 6) {
                            Text(user.username)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            CircularProfileImageView(user: user, size: .xSmall)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Photo or video goes here
            media()

            // Action row
            HStack {
                HStack(spacing: 20) {
                    Button {
                        Task { didLike ? try await viewModel.unlike() : try await viewModel.like() }
                    } label: {
                        Image(systemName: didLike ? "heart.fill" : "heart")
                            .resizable().frame(width: 25, height: 23)
                            .foregroundColor(didLike ? .red : .primary)
                    }
                    Button { showCommentsSheet = true } label: {
                        Image(systemName: "bubble.right")
                            .resizable().frame(width: 24, height: 22)
                            .foregroundColor(.primary)
                    }
                    Button {
                        if didBookmark { Task { try await viewModel.unbookmark() } }
                        else { showBookmarkSheet = true }
                    } label: {
                        Image(systemName: didBookmark ? "bookmark.fill" : "bookmark")
                            .resizable().frame(width: 19, height: 23)
                            .foregroundColor(didBookmark ? .cyan : .primary)
                    }
                }
                Spacer()
                Button {
                    selectedOptionsOption = nil
                    showOptionsSheet.toggle()
                } label: {
                    Image(systemName: "ellipsis").imageScale(.large).foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Text(likeCountText)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if !viewModel.post.caption.isEmpty {
                CaptionBlock(username: viewModel.post.user?.username ?? "", caption: viewModel.post.caption)
                    .padding(.horizontal, 16)
                    .padding(.top, 5)
            }

            Button { showCommentsSheet = true } label: {
                Text("View all \(viewModel.commentString)")
                    .font(.footnote).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            Text(viewModel.timestampString)
                .font(.caption).foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 14)
        }
        .background(Color(.systemBackground))
        .onAppear { if autoOpenComments { showCommentsSheet = true } }
        .sheet(isPresented: $showCommentsSheet) {
            CommentsView(post: viewModel.post)
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBookmarkSheet) {
            BookmarkSheet(
                userId: Auth.auth().currentUser?.uid ?? "",
                onSelectCollection: { viewModel.bookmarkPost(collectionId: $0.id ?? "") },
                onCreateCollection: { viewModel.createCollectionAndBookmark(name: $0) }
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
                showOptionsSheet = false
                showSharePostSheet = true
                selectedOptionsOption = nil
            } else if option == .delete {
                DeleteManager.shared.delete(viewModel.post)
                dismiss()
                selectedOptionsOption = nil
            }
        }
        .sheet(isPresented: $showSharePostSheet) {
            SharePostSheetView(post: viewModel.post)
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct InlineVideoView: View {
    let post: Post
    @ObservedObject var playback: FeedPlaybackCoordinator
    var onDoubleTap: () -> Void
    var onOpen: () -> Void

    private var isActive: Bool { playback.activePostId == post.id }

    var body: some View {
        ZStack {
            Color.black
            if let thumb = post.thumbnailUrl {
                KFImage(URL(string: thumb)).resizable().scaledToFit()
            }
            if isActive {
                VideoPlayerController(player: playback.player)
                    .allowsHitTesting(false)
            }
        }
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleTap() }
        .onTapGesture { onOpen() }
        .overlay(alignment: .bottomTrailing) {   // after the tap gestures so the button wins its own taps
            if isActive {
                Button {
                    playback.toggleMute()
                } label: {
                    Image(systemName: playback.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(10)
            }
        }
    }
}
