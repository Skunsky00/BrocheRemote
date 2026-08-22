//
//  LocationPhotoStripView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/17/26.
//

import SwiftUI
import Kingfisher

struct LocationPhotoGridPreview: View {
    let location: Location
    let isCurrentUser: Bool
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var loadedForLocationId: String?
    
    private let previewLimit = 6
    private let columns = [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 20)
            } else if posts.isEmpty {
                Text(isCurrentUser ? "No photos yet. Tap the camera above to add one." : "No photos yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                GeometryReader { geo in
                    let tileSize = (geo.size.width - 6) / 2   // 6 = the single inter-column spacing
                    
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(posts.prefix(previewLimit)) { post in
                            NavigationLink(destination: destinationView(for: post)) {
                                Group {
                                    if let thumb = post.thumbnailUrl ?? post.imageUrl {
                                        KFImage(URL(string: thumb)).resizable().scaledToFill()
                                    } else if let videoUrlString = post.videoUrl, let videoUrl = URL(string: videoUrlString) {
                                        VideoThumbnail(url: videoUrl).scaledToFill()
                                    }
                                }
                                .frame(width: tileSize, height: tileSize)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }
                .frame(height: gridHeight)
                
                if posts.count > previewLimit {
                    NavigationLink(destination: PostGridView(config: .location(location))) {
                        Text("View All \(posts.count) Photos")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .task { await load() }
    }
    @ViewBuilder
    private func destinationView(for post: Post) -> some View {
        if let videoUrl = post.videoUrl, !videoUrl.isEmpty {
            PostGridFeedCell(viewModel: FeedCellViewModel(post: post))
        } else {
            PostGridFeedCellPhoto(viewModel: FeedCellViewModel(post: post))
        }
    }
    
    private var gridHeight: CGFloat {
        let rowCount = Int(ceil(Double(min(posts.count, previewLimit)) / 2.0))
        let approxTileHeight = (UIScreen.main.bounds.width - 32 - 48 - 6) / 2   // rough estimate for row height
        return CGFloat(rowCount) * approxTileHeight + CGFloat(max(rowCount - 1, 0)) * 6
    }
    
    private func load() async {
        guard loadedForLocationId != location.id else { return }   // NEW — skip if already loaded for this pin
        isLoading = true
        posts = (try? await PostService.fetchPosts(forLocationId: location.id)) ?? []
        loadedForLocationId = location.id   // NEW
        isLoading = false
    }
}
