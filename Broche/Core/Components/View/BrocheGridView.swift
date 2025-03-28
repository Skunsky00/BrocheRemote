//
//  BrocheGridView.swift
//  Broche
//
//  Created by Jacob Johnson on 3/25/25.
//

import SwiftUI
import Kingfisher
import AVKit

struct BrocheGridView: View {
    let user: User
    @StateObject private var viewModel: BrocheGridViewModel
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: BrocheGridViewModel(user: user))
    }
    
    private let gridItems: [GridItem] = [
        .init(.flexible(), spacing: 2),
        .init(.flexible(), spacing: 2),
        .init(.flexible(), spacing: 2)
    ]
    private let cellWidth: CGFloat = (UIScreen.main.bounds.width - 4) / 3
    private let cellHeight: CGFloat = ((UIScreen.main.bounds.width - 4) / 3) * 16 / 9
    
    var body: some View {
        VStack {
            if viewModel.pinnedPosts.allSatisfy({ $0 == nil }) {
                VStack {
                    Image(systemName: "pin.fill")
                        .imageScale(.large)
                        .padding()
                    Text("No pinned posts yet. Pin your favorites!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 150)
            } else {
                LazyVGrid(columns: gridItems, spacing: 2) {
                    ForEach(0..<9, id: \.self) { index in
                        if let post = viewModel.pinnedPosts[index] {
                            NavigationLink(destination: PostGridFeedCell(viewModel: FeedCellViewModel(post: post))) {
                                BrocheGridCell(post: post, width: cellWidth, height: cellHeight)
                            }
                            .onLongPressGesture {
                                print("Unpinning post at index: \(index)")
                                viewModel.unpinPost(post)
                            }
                        } else {
                            Color.gray.opacity(0.2)
                                .frame(width: cellWidth, height: cellHeight)
                        }
                    }
                }
                .padding(2)
            }
        }
    }
}

struct BrocheGridCell: View {
    let post: Post
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            if let thumbnailUrl = post.thumbnailUrl {
                KFImage(URL(string: thumbnailUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else if let imageUrl = post.imageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else if let videoUrlString = post.videoUrl, let videoUrl = URL(string: videoUrlString) {
                VideoThumbnail(url: videoUrl)
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            }
            
            VStack {
                Text(post.location)
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                    .padding(.top, height - 30) // Adjust text position for taller cell
            }
        }
    }
}

#Preview {
    BrocheGridView(user: User.MOCK_USERS[0])
}
