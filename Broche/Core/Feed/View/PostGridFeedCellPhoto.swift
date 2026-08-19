//
//  PostGridFeedCellPhoto.swift
//  Broche
//
//  Created by Jacob Johnson on 8/17/26.
//

import SwiftUI
import Kingfisher
import AVKit
import Firebase

struct PostGridFeedCellPhoto: View {
    @ObservedObject var viewModel: FeedCellViewModel
    @State private var showOptionsSheet = false
    @State private var showSharePostSheet = false
    @State private var selectedOptionsOption: OptionsItemModel?
    @State private var showDetail = false
    @State private var showCommentsSheet = false
    @State private var showBookmarkSheet = false

    var showDeleteOption: Bool { viewModel.post.isCurrentUser }
    var didLike: Bool { viewModel.post.didLike ?? false }
    var didBookmark: Bool { viewModel.post.didBookmark ?? false }

    // NEW — proper 0/1/plural formatting
    private var likeCountText: String {
        switch viewModel.post.likes {
        case 0: return "0 likes"
        case 1: return "1 like"
        default: return "\(viewModel.post.likes) likes"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Header: location + profile pic, above the image
            HStack(spacing: 8) {
                NavigationLink(destination: MapViewForLocation(location: viewModel.post.location)) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                        Text(viewModel.post.location)
                            .font(.subheadline.weight(.semibold))   // CHANGED — was .footnote
                            .lineLimit(1)
                    }
                    .foregroundStyle(.primary)
                }

                Spacer()

                if let user = viewModel.post.user {
                    NavigationLink(value: user) {
                        HStack(spacing: 6) {
                            Text(user.username)
                                .font(.subheadline.weight(.semibold))   // NEW — username visible up top too
                                .foregroundStyle(.primary)
                            CircularProfileImageView(user: user, size: .xSmall)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 10)

            // MARK: - Image
            if let imageUrl = viewModel.post.imageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                    .clipped()
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        TapGesture(count: 2).onEnded { handleDoubleTap() }
                    )
            }

            // MARK: - Action row: like/comment/bookmark left, ellipsis right
            HStack {
                HStack(spacing: 20) {   // CHANGED — was 18, a touch more breathing room
                    Button {
                        Task { didLike ? try await viewModel.unlike() : try await viewModel.like() }
                    } label: {
                        Image(systemName: didLike ? "heart.fill" : "heart")   // CHANGED — outline when not liked, cleaner than always-filled
                            .resizable()
                            .frame(width: 25, height: 23)
                            .foregroundColor(didLike ? .red : .primary)
                    }

                    Button {
                        showCommentsSheet.toggle()
                    } label: {
                        Image(systemName: "bubble.right")   // CHANGED — .right reads slightly friendlier than .left in this spot
                            .resizable()
                            .frame(width: 24, height: 22)
                            .foregroundColor(.primary)
                    }

                    Button {
                        if didBookmark {
                            Task { try await viewModel.unbookmark() }
                        } else {
                            showBookmarkSheet = true
                        }
                    } label: {
                        Image(systemName: didBookmark ? "bookmark.fill" : "bookmark")   // CHANGED — same outline treatment
                            .resizable()
                            .frame(width: 19, height: 23)
                            .foregroundColor(didBookmark ? .cyan : .primary)
                    }
                }

                Spacer()

                Button {
                    selectedOptionsOption = nil
                    showOptionsSheet.toggle()
                } label: {
                    Image(systemName: "ellipsis")
                        .imageScale(.large)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)   // CHANGED — was 10

            // MARK: - Likes count
            Text(likeCountText)   // CHANGED — now uses the formatted string
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 8)   // CHANGED — was 6

            // MARK: - Caption
            if !viewModel.post.caption.isEmpty {
                HStack(alignment: .top, spacing: 5) {
                    Text(viewModel.post.user?.username ?? "")
                        .fontWeight(.semibold)
                    Text(viewModel.post.caption)
                }
                .font(.subheadline)   // CHANGED — was size 14, now scales with Dynamic Type
                .padding(.horizontal, 16)
                .padding(.top, 5)   // CHANGED — was 4
            }

            // MARK: - View comments
            Button {
                showCommentsSheet = true
            } label: {
                Text("View all \(viewModel.commentString)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)   // CHANGED — was 4

            // MARK: - Timestamp
            Text(viewModel.timestampString)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 6)   // CHANGED — was 4
                .padding(.bottom, 14)   // CHANGED — was 12
        }
        .background(Color(.systemBackground))
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
                showOptionsSheet = false
                showSharePostSheet = true
                selectedOptionsOption = nil
            } else if option == .delete {
                Task { try await viewModel.deletePost() }
                selectedOptionsOption = nil
            } else if option == .pinToBroche {
                showDetail.toggle()
                selectedOptionsOption = nil
            }
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
        Task {
            do {
                try await viewModel.like()
            } catch {
                print("Error liking post: \(error)")
            }
        }
    }
}
