//
//  FeedCell.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import Kingfisher

struct FeedCell: View {
    let post: Post
    
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
                Text(post.location)
                            .font(.footnote)
                            
                        
                    
                
                Spacer()
                
                if let user = post.user {
                    CircularProfileImageView(user: user, size: .xSmall)
                }
                
               }
            .padding(.horizontal,12 )
            
            // post image
            KFImage(URL(string: post.imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: 400)
                        .clipped()
                        .contentShape(Rectangle())
            
            //action buttons
            HStack(spacing: 16) {
                Button {
                    print("like post")
                   // didLike ? viewModel.unlike() : viewModel.like()
                } label: {
                    Image(systemName: "heart")
                        .imageScale(.large)
                }
                
                Spacer()
                
            Button {
                print("save post")
             //   didBookmark ? viewModel.unbookmark() : viewModel.bookmark()
                } label: {
                    Image(systemName:"bookmark")
                        .imageScale(.large)
                }
                
                Spacer()
                
                Button {
                    //   NavigationLink(destination: CommentsView(post: viewModel.post)) {
                    print("comment on post")
               // }
                } label: {
                    Image(systemName: "bubble.left")
                        .imageScale(.large)
                }
                
                Spacer()
                
                Button {
                print("share post")
                } label: {
                    Image(systemName: "ellipsis")
                        .imageScale(.large)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 3)
            .foregroundColor(.black)
            
            //likes and comments lable
            HStack {
                Text("\(post.likes) likes")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 1)
                    
                       Spacer()
                
                // filter name
                Text(post.label)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .frame(minWidth: 50)
                    .padding(.top, 1)
                    .background(.gray)
                
                  }
            .padding(.horizontal, 12)
            .padding(.bottom, 1)
            
            // caption - broche description
            HStack {
                    Text("\(post.user?.username ?? "") ").fontWeight(.semibold) +
                Text(post.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.footnote)
            .padding(.leading, 10)
            .padding(.top, 1)
                
            Text("2d")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
                .padding(.top, 1)
                .foregroundColor(.gray)
                
            
        }
    }
}

    

struct FeedCell_Previews: PreviewProvider {
    static var previews: some View {
        FeedCell(post: Post.MOCK_POSTS[4])
    }
}
