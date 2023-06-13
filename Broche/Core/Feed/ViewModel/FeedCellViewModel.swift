//
//  FeedCellViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import SwiftUI
import Firebase

@MainActor
class FeedCellViewModel: ObservableObject {
    @Published var post: Post
    
    var likeString: String {
        let label = post.likes == 1 ? "like" : "likes"
        return "\(post.likes) \(label)"
    }
    
    var timestampString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: post.timestamp.dateValue(), to: Date()) ?? ""
    }
    
    init(post: Post) {
        self.post = post
        
        Task { try await checkIfUserLikedPost()
            try await checkIfUserBookmarkedPost()
        }
    }
    
   
    
    func deletePost() async throws {
        print("Deleting post...")
                try await PostService.deletePost(post)
                print("Post deleted.")
            
            // Additional logic after deleting the post (e.g., navigating back to the feed)
        }
    
    func like() async throws {
        self.post.didLike = true
        Task {
            try await PostService.likePost(post)
            self.post.likes += 1
        }
    }
    
    func unlike() async throws {
        self.post.didLike = false
        Task {
            try await PostService.unlikePost(post)
            self.post.likes -= 1
        }
    }
    
    func checkIfUserLikedPost() async throws {
        self.post.didLike = try await PostService.checkIfUserLikedPost(post)
    }
    
    func bookmark() async throws {
        self.post.didBookmark = true
        Task {
            try await PostService.BookmarkPost(post)
        }
    }
    
    func unbookmark() async throws {
        self.post.didBookmark = false
        Task {
            try await PostService.unBookmarkPost(post)
        }
    }
    
    func checkIfUserBookmarkedPost() async throws {
        self.post.didBookmark = try await PostService.checkIfUserBookmarkedPost(post)
    }
}

