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
        }
    }
    
    var body: some View {
        VStack {
            if !posts.isEmpty {
                // SearchBar inside the scrollable content, but only if there are posts
                SearchBar(text: $searchText, isEditing: $isEditing)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
            
            if posts.isEmpty {
                VStack {
                    Image(systemName: noPostImage)
                        .imageScale(.large)
                        .padding()
                    
                    Text(noPostsMessage)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 150)
                
            } else {
                
                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 1) {
                        ForEach(posts) { post in
                            NavigationLink(destination: PostGridFeedCell(viewModel: FeedCellViewModel(post: post))){
                                
                                ZStack {
                                    if let imageUrl = post.imageUrl {
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
                                    
                                    VStack {
                                        Text(post.location)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                            .foregroundColor(.white)
                                        
                                        HStack {
                                            Text(post.label!)
                                                .font(.footnote)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Text("\(post.likes)")
                                                .font(.footnote)
                                                .frame(maxWidth: .infinity, alignment: .trailing)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.trailing, 8)
                                    }
                                    .padding(.leading, 8)
                                    .padding(.top, 140)
                                }
                            }
//                            .onAppear {
//                                guard let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) else { return }
//                                if case .explore = config, index == viewModel.posts.count - 1 {
//                                    Task {
//                                        await viewModel.fetchExplorePagePosts()
//                                    }
//                                }
//                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
    }
}









struct PostGridView_Previews: PreviewProvider {
    static var previews: some View {
        PostGridView(config: .profile(User.MOCK_USERS[0]))
    }
}
    
