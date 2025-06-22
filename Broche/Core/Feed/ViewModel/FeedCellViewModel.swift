//
//  FeedCellViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import Foundation
import Firebase

@MainActor
class FeedCellViewModel: ObservableObject {
    @Published var post: Post
    
    var likeString: String {
        let likes = post.likes
        switch likes {
        case 0..<1000:
            return "\(likes)"
        case 1000..<10000:
            let formattedLikes = Double(likes) / 1000.0
            return String(format: "%.1fK", formattedLikes)
        case 10000...:
            let formattedLikes = Double(likes) / 1000.0
            return String(format: "%.0fK", formattedLikes)
        default:
            return "\(likes)"
        }
    }
    
    var commentString: String {
        let comments = post.comments
        switch comments {
        case 0..<1000:
            return "\(comments)"
        case 1000..<10000:
            let formattedLikes = Double(comments) / 1000.0
            return String(format: "%.1fK", formattedLikes)
        case 10000...:
            let formattedLikes = Double(comments) / 1000.0
            return String(format: "%.0fK", formattedLikes)
        default:
            return "\(comments)"
        }
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
        Task {
            try await checkIfUserLikedPost()
            try await checkIfUserBookmarkedPost()
        }
    }
    
    func deletePost() async throws {
        print("Deleting post...")
        try await PostService.deletePost(post)
        print("Post deleted.")
    }
    
    func like() async throws {
        self.post.didLike = true
        try await PostService.likePost(post)
        self.post.likes += 1
    }
    
    func unlike() async throws {
        self.post.didLike = false
        try await PostService.unlikePost(post)
        self.post.likes -= 1
    }
    
    func checkIfUserLikedPost() async throws {
        self.post.didLike = try await PostService.checkIfUserLikedPost(post)
    }
    
    func bookmarkPost(collectionId: String) {
        guard let postId = post.id, let userId = Auth.auth().currentUser?.uid else {
            print("Cannot bookmark post: Missing post ID or user ID")
            return
        }
        Task {
            do {
                try await PostService.addPostToCollection(userId: userId, collectionId: collectionId, postId: postId)
                self.post.didBookmark = true
                print("Post \(postId) bookmarked to collection \(collectionId)")
            } catch {
                print("Error bookmarking post: \(error.localizedDescription)")
            }
        }
    }
    
    func unbookmark() async throws {
        guard let postId = post.id, let userId = Auth.auth().currentUser?.uid else {
            print("Cannot unbookmark post: Missing post ID or user ID")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing post ID or user ID"])
        }
        try await PostService.removePostFromAllCollections(userId: userId, postId: postId)
        self.post.didBookmark = false
        print("Post \(postId) unbookmarked from all collections")
    }
    
    func checkIfUserBookmarkedPost() async throws {
        guard let postId = post.id, let userId = Auth.auth().currentUser?.uid else {
            print("Cannot check bookmark status: Missing post ID or user ID")
            self.post.didBookmark = false
            return
        }
        self.post.didBookmark = try await PostService.isPostInAnyCollection(userId: userId, postId: postId)
    }
    
    func createCollectionAndBookmark(name: String) {
        guard let postId = post.id, let userId = Auth.auth().currentUser?.uid else {
            print("Cannot create collection: Missing post ID or user ID")
            return
        }
        Task {
            do {
                if let newCollection = try await PostService.createCollection(userId: userId, name: name) {
                    try await PostService.addPostToCollection(userId: userId, collectionId: newCollection.id ?? "", postId: postId)
                    self.post.didBookmark = true
                    print("Created collection \(name) and bookmarked post \(postId)")
                } else {
                    print("Failed to create collection")
                }
            } catch {
                print("Error creating collection or bookmarking post: \(error.localizedDescription)")
            }
        }
    }
}
