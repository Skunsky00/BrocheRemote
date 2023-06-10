//
//  FeedCell.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import Kingfisher
import AVKit

struct FeedCell: View {
    @ObservedObject var viewModel: FeedCellViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var didLike: Bool { return viewModel.post.didLike ?? false }
    var didBookmark: Bool { return viewModel.post.didBookmark ?? false }
    
    var body: some View {
        VStack(alignment: .leading) {
            
            //user profile and username and location
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundColor(.gray)
                        .frame(width: 55, height: 55)
                    
                    Button(action: {
                        print("open location page")
                    }, label: {
                        Image(systemName: "mappin.circle")
                            .imageScale(.large)
                            .foregroundColor(.black)
                    })
                }
                Text(viewModel.post.location)
                            .font(.footnote)
                            
                        
                    
                
                Spacer()
                
                if let user = viewModel.post.user {
                    NavigationLink(value: user) {
                        CircularProfileImageView(user: user, size: .xSmall)
                    }
                }
                
               }
            .padding(.horizontal,12 )
            
            // post image
            if let imageUrl = viewModel.post.imageUrl {
                            KFImage(URL(string: imageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.1)
                                .clipped()
                                .contentShape(Rectangle())
                        }/* else if let videoUrl = viewModel.post.videoUrl {
                            VideoPlayer(player: AVPlayer(url: URL(string: videoUrl)!))
                                .frame(width: UIScreen.main.bounds.width, height: 400)
                        }*/
            
            //action buttons
            HStack(spacing: 16) {
                Button {
                    print("like post")
                    Task { didLike ? try await viewModel.unlike() : try await viewModel.like() }
                } label: {
                    Image(systemName: didLike ? "heart.fill" : "heart")
                        .imageScale(.large)
                        .foregroundColor(didLike ? .red : colorScheme == .dark ? .white : .black)
                }
                
                Spacer()
                
            Button {
                print("save post")
                Task {  didBookmark ? try await viewModel.unbookmark() : try await viewModel.bookmark() }
                } label: {
                    Image(systemName: didBookmark ? "bookmark.fill" : "bookmark")
                        .imageScale(.large)
                        .accentColor(colorScheme == .dark ? .white : .black)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                Spacer()
                
                NavigationLink(destination: CommentsView(post: viewModel.post)) {
                    Image(systemName: "bubble.left")
                        .imageScale(.large)
                        .accentColor(colorScheme == .dark ? .white : .black)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                Spacer()
                
                Button {
                print("share post")
                } label: {
                    Image(systemName: "ellipsis")
                        .imageScale(.large)
                        .accentColor(colorScheme == .dark ? .white : .black)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 3)
            .foregroundColor(.black)
            
            //likes and comments lable
            HStack {
                NavigationLink(value: SearchViewModelConfig.likes(viewModel.post.id ?? "")) {
                    Text(viewModel.likeString)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 1)
                }
                               
                       Spacer()
                
                // filter name
                Text(viewModel.post.label)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .frame(minWidth: 50)
                    .padding(.top, 1)
                    .background(.gray)
                
                  }
            .padding(.horizontal, 12)
            .padding(.bottom, 1)
            
            // caption - broche description
                    HStack {
                        Text("\(viewModel.post.user?.username ?? "") ").fontWeight(.semibold) +
                        Text(viewModel.post.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.footnote)
                    .padding(.leading, 10)
                    .padding(.top, 1)
                
                
            Text(viewModel.timestampString)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
                .padding(.top, 1)
                .foregroundColor(.gray)
                
            
        }
        .navigationDestination(for: SearchViewModelConfig.self) { config in
            UserListView(config: config)}
    }
}

    

struct FeedCell_Previews: PreviewProvider {
    static var previews: some View {
        FeedCell(viewModel: FeedCellViewModel(post: Post.MOCK_POSTS[4]))
    }
}
