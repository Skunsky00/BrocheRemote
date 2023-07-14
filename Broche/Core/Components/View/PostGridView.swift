//
//  PostGridView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import Kingfisher

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
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, isEditing: $isEditing)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
            ScrollView {
                LazyVGrid(columns: gridItems, spacing: 1) {
                    ForEach(posts) { post in
                        NavigationLink(destination: FeedCell(viewModel: FeedCellViewModel(post: post))) {
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
                                
                                Text(post.location)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 8)
                                    .padding(.top, 140)
                                    .foregroundColor(.white)
                            }
                        }
                        .onAppear {
                            guard let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) else { return }
                            if case .explore = config, index == viewModel.posts.count - 1 {
                                Task {
                                    await viewModel.fetchExplorePagePosts()
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
}


struct PostGridView_Previews: PreviewProvider {
    static var previews: some View {
        PostGridView(config: .profile(User.MOCK_USERS[0]))
    }
}
    
