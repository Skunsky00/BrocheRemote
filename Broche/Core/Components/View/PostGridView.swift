//
//  PostGridView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import Kingfisher
import AVKit

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) { self.build = build }
    var body: some View { build() }
}

/// Used by screens that don't own their view model (collection, visit, location).
/// Same name and init as before, so those screens keep compiling.
struct PostGridView: View {
    let config: PostGridConfiguration
    @StateObject private var viewModel: PostGridViewModel

    init(config: PostGridConfiguration) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: PostGridViewModel(loader: Self.loader(for: config)))
    }

    var body: some View {
        PostGridContent(config: config, viewModel: viewModel)
    }

    private static func loader(for config: PostGridConfiguration) -> PostGridViewModel.PageLoader {
        switch config {
        case .profile(let user):
            return { try await PostService.fetchUserPosts(user: user, after: $0) }
        case .likedPosts(let user):
            return { try await PostService.fetchLikedPosts(forUserID: user.id, after: $0) }
        case .bookmarkedPosts(let user):
            return { try await PostService.fetchBookmarkedPosts(forUserID: user.id, after: $0) }
        case .collectionPosts(let userId, let collectionId):
            return { _ in
                let posts = try await PostService.fetchPostsInCollection(userId: userId, collectionId: collectionId)
                return (posts, nil)
            }
        case .visit(let visit):
            return { _ in
                let posts = try await PostService.fetchPosts(forVisitId: visit.id)
                return (posts, nil)
            }
        case .location(let location):
            return { _ in
                let posts = try await PostService.fetchPosts(forLocationId: location.id)
                return (posts, nil)
            }
        }
    }
}

/// The actual grid. Takes a view model from outside so it survives tab switches.
struct PostGridContent: View {
    let config: PostGridConfiguration
    @ObservedObject var viewModel: PostGridViewModel
    @State private var isEditing = false
    @State private var searchText = ""

    var posts: [Post] {
        searchText.isEmpty ? viewModel.posts : viewModel.filteredPosts(searchText)
    }

    private let gridItems: [GridItem] = [
        .init(.flexible(), spacing: 8),
        .init(.flexible(), spacing: 8)
    ]
    private let horizontalPadding: CGFloat = 12
    private var cellWidth: CGFloat { (UIScreen.main.bounds.width - horizontalPadding * 2 - 8) / 2 }
    private var cellHeight: CGFloat { cellWidth * 1.25 }   // 4:5 portrait

    private let imageDimension: CGFloat = (UIScreen.main.bounds.width / 2) - 1

    var noPostsMessage: String {
        switch config {
        case .likedPosts:      return "No liked posts yet."
        case .bookmarkedPosts: return "No bookmarked posts yet."
        case .profile:         return "No posts yet."
        case .collectionPosts: return "No posts in this collection yet."
        case .visit:           return "No posts in this visit yet."
        case .location:        return "No posts for this location yet."
        }
    }

    var noPostImage: String {
        switch config {
        case .likedPosts:                        return "heart"
        case .bookmarkedPosts, .collectionPosts: return "bookmark"
        case .profile, .visit, .location:        return "camera"
        }
    }

    var showsSearchBar: Bool {
        if case .visit = config { return false }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if !viewModel.posts.isEmpty && showsSearchBar {
                    SearchBar(text: $searchText, isEditing: $isEditing)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }

                if posts.isEmpty {
                    VStack {
                        Image(systemName: searchText.isEmpty ? noPostImage : "magnifyingglass")
                            .imageScale(.large)
                            .padding()
                        Text(searchText.isEmpty ? noPostsMessage : "No results for \"\(searchText)\"")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 150)
                } else {
                    LazyVGrid(columns: gridItems, spacing: 8) {
                        ForEach(posts) { post in
                            NavigationLink(destination: LazyView(destinationView(for: post))) {
                                cell(for: post)
                            }
                            .buttonStyle(.plain)
                            .onAppear { viewModel.loadMoreIfNeeded(current: post) }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .task { viewModel.loadIfNeeded() }
        .refreshable { viewModel.refresh() }
    }

    private func cell(for post: Post) -> some View {
        let isVideo = !(post.videoUrl ?? "").isEmpty

        return ZStack(alignment: .bottomLeading) {
            if let thumbnailUrl = post.thumbnailUrl {
                GridThumbnail(url: URL(string: thumbnailUrl), width: cellWidth, height: cellHeight)
            } else if let imageUrl = post.imageUrl {
                GridThumbnail(url: URL(string: imageUrl), width: cellWidth, height: cellHeight)
            } else if let videoUrlString = post.videoUrl, let videoUrl = URL(string: videoUrlString) {
                VideoThumbnail(url: videoUrl)
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .clipped()
            }

            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                Text(post.location)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .padding(10)
        }
        .frame(width: cellWidth, height: cellHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if isVideo {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(7)
                    .background(.black.opacity(0.35), in: Circle())
                    .padding(8)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for post: Post) -> some View {
        if let videoUrl = post.videoUrl, !videoUrl.isEmpty {
            PostGridFeedCell(viewModel: FeedCellViewModel(post: post))
        } else {
            PostGridFeedCellPhoto(viewModel: FeedCellViewModel(post: post))
        }
    }
}

struct GridThumbnail: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        KFImage(url)
            .placeholder { Color.gray.opacity(0.15) }
            .fade(duration: 0.2)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
    }
}


struct PostGridView_Previews: PreviewProvider {
    static var previews: some View {
        PostGridView(config: .profile(User.MOCK_USERS[0]))
    }
}

