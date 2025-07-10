//
//  MessageView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI
import Kingfisher
import AVFoundation

struct MessageView: View {
    let viewModel: MessageViewModel
    @State private var post: Post?
    @State private var thumbnailImage: UIImage? // For generated video thumbnails
    
    var body: some View {
        HStack {
            if viewModel.isFromCurrentUser {
                Spacer()
                if let postId = viewModel.postId, !postId.isEmpty {
                    // Shared post preview
                    NavigationLink {
                        postDestination
                    } label: {
                        postPreview
                    }
                    .padding(.leading, 100)
                    .padding(.trailing)
                } else {
                    // Regular text message
                    Text(viewModel.message.text)
                        .font(.system(size: 15))
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(ChatBubble(isFromCurrentUser: true))
                        .foregroundColor(.white)
                        .padding(.leading, 100)
                        .padding(.trailing)
                }
            } else {
                HStack(alignment: .bottom) {
                    if let user = viewModel.message.user {
                        CircularProfileImageView(user: user, size: .xSmall)
                    }
                    
                    if let postId = viewModel.postId, !postId.isEmpty {
                        // Shared post preview
                        NavigationLink {
                            postDestination
                        } label: {
                            postPreview
                        }
                    } else {
                        // Regular text message
                        Text(viewModel.message.text)
                            .font(.system(size: 15))
                            .padding(10)
                            .background(Color.gray.opacity(0.8)) // Improved dark mode visibility
                            .clipShape(ChatBubble(isFromCurrentUser: false))
                            .foregroundColor(.black)
                    }
                }
                .padding(.trailing, 100)
                .padding(.leading)
                
                Spacer()
            }
        }
        .onAppear {
            if let postId = viewModel.postId, !postId.isEmpty {
                fetchPost(postId: postId)
            }
            print("🔔 MessageView onAppear - post: \(String(describing: post)), type: \(type(of: post)), isRead: \(viewModel.message.isRead)")
        }
    }
    
    private var postPreview: some View {
        VStack(alignment: .leading) {
            if let post = post {
                Group {
                    if let thumbnailUrl = post.thumbnailUrl {
                        KFImage(URL(string: thumbnailUrl))
                            .resizable()
                            .scaledToFill()
                    } else if let imageUrl = post.imageUrl {
                        KFImage(URL(string: imageUrl))
                            .resizable()
                            .scaledToFill()
                    } else if let videoUrl = post.videoUrl, let url = URL(string: videoUrl) {
                        if let thumbnailImage = thumbnailImage {
                            Image(uiImage: thumbnailImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.gray
                                .onAppear {
                                    generateThumbnailImage(for: url)
                                }
                        }
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
            } else {
                // Placeholder while loading
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .padding(10)
        .background(viewModel.isFromCurrentUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var postDestination: some View {
        Group {
            if let post = post {
                PostGridFeedCell(viewModel: FeedCellViewModel(post: post))
            } else {
                Text("Post not found")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func fetchPost(postId: String) {
        Task {
            do {
                let snapshot = try await COLLECTION_POSTS.document(postId).getDocument()
                guard let rawData = snapshot.data() else {
                    print("❌ No data for post \(postId)")
                    return
                }
                print("🔔 Firestore raw data for post \(postId): \(rawData)")
                if let thumbnailUrl = rawData["thumbnailUrl"] as? String {
                    print("🔔 Fetched thumbnailUrl for post \(postId): \(thumbnailUrl)")
                } else {
                    print("❌ No thumbnailUrl found for post \(postId)")
                }
                
                do {
                    let postData = try snapshot.data(as: Post.self)
                    self.post = postData
                    print("✅ Fetched post with ID: \(postId), thumbnailUrl: \(String(describing: postData.thumbnailUrl))")
                } catch {
                    print("❌ Decoding error for post \(postId): \(error.localizedDescription)")
                }
            } catch {
                print("❌ Error fetching post \(postId): \(error.localizedDescription)")
            }
        }
    }
    
    private func generateThumbnailImage(for url: URL) {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0.5, preferredTimescale: 600)
        
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, error in
            if let error = error {
                print("❌ Error generating thumbnail for post \(self.viewModel.postId ?? "unknown"): \(error.localizedDescription)")
                return
            }
            if let image = image {
                DispatchQueue.main.async {
                    self.thumbnailImage = UIImage(cgImage: image)
                    print("✅ Generated thumbnail for post \(self.viewModel.postId ?? "unknown")")
                }
            }
        }
    }
}
