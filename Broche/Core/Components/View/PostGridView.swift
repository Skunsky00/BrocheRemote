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
    
    init(config: PostGridConfiguration) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: PostGridViewModel(config: config))
    }
    
    private let gridItems: [GridItem] = [
        .init(.flexible(), spacing: 1),
        .init(.flexible(), spacing: 1)
    ]
    
    private let imageDimension: CGFloat =  (UIScreen.main.bounds.width / 2) - 1
    
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 1, content:  {
            ForEach(viewModel.posts) { post in
                NavigationLink(value: post) {
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
                        viewModel.fetchExplorePagePosts()
                    }
                }
            }
        })
        .navigationDestination(for: Post.self) { post in
            FeedCell(viewModel: FeedCellViewModel(post: post))
        }
    }
}

struct PostGridView_Previews: PreviewProvider {
    static var previews: some View {
        PostGridView(config: .profile(User.MOCK_USERS[0]))
    }
}
    
