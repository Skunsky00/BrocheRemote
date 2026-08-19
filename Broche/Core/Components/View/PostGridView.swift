//
//  PostGridView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import Kingfisher
import AVKit

struct PostGridView: View {
    let config: PostGridConfiguration
    @StateObject var viewModel: PostGridViewModel
    @State private var isEditing = false
    @State private var searchText = ""
    
    init(config: PostGridConfiguration) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: PostGridViewModel(config: config))
    }
    
    var posts: [Post] {
        return searchText.isEmpty ? viewModel.posts : viewModel.filteredPosts(searchText)
    }
    
    private let gridItems: [GridItem] = [
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1)
    ]
    
    private let imageDimension: CGFloat = (UIScreen.main.bounds.width / 2) - 1
    
    var noPostsMessage: String {
        switch config {
        case .likedPosts:
            return "No liked posts yet."
        case .bookmarkedPosts:
            return "No bookmarked posts yet."
        case .profile:
            return "No posts yet."
        case .explore:
            return "No posts to display."
        case .collectionPosts:
            return "No posts in this collection yet."
        case .visit:
            return "No posts in this visit yet."
        case .location:
            return "No posts for this location yet."
        }
    }
    
    var noPostImage: String {
        switch config {
        case .likedPosts:
            return "heart"
        case .bookmarkedPosts:
            return "bookmark"
        case .profile:
            return "camera"
        case .explore:
            return "camera"
        case .collectionPosts:
            return "bookmark"
        case .visit:
            return "camera"
        case .location:
            return "camera"
        }
    }
    
    var showsSearchBar: Bool {
        switch config {
        case .visit:
            return false
        default:
            return true
        }
    }
    
    var body: some View {
        VStack {
            if !viewModel.posts.isEmpty && showsSearchBar {   // CHANGED — was `!posts.isEmpty`
                SearchBar(text: $searchText, isEditing: $isEditing)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
            
            if posts.isEmpty {
                VStack {
                    Image(systemName: searchText.isEmpty ? noPostImage : "magnifyingglass")   // CHANGED
                        .imageScale(.large)
                        .padding()
                    
                    Text(searchText.isEmpty ? noPostsMessage : "No results for \"\(searchText)\"")   // CHANGED
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 150)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 1) {
                        ForEach(posts) { post in
                            NavigationLink(destination: destinationView(for: post)) {
                                ZStack(alignment: .bottom) {
                                    if let thumbnailUrl = post.thumbnailUrl {
                                        KFImage(URL(string: thumbnailUrl))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: imageDimension, height: imageDimension)
                                            .clipped()
                                    } else if let imageUrl = post.imageUrl {
                                        KFImage(URL(string: imageUrl))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: imageDimension, height: imageDimension)
                                            .clipped()
                                    } else if let videoUrlString = post.videoUrl, let videoUrl = URL(string: videoUrlString) {
                                        VideoThumbnail(url: videoUrl)
                                            .scaledToFill()
                                            .frame(width: imageDimension, height: imageDimension)
                                            .clipped()
                                    }
                                    
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.6)],
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )
                                    .frame(width: imageDimension, height: imageDimension)
                                    
                                    HStack {
                                        Text(post.location)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Text("\(post.likes)")
                                            .font(.footnote)
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
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



struct PostGridView_Previews: PreviewProvider {
    static var previews: some View {
        PostGridView(config: .profile(User.MOCK_USERS[0]))
    }
}

