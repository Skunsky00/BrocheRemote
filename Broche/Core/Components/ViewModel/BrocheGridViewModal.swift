//
//  BrocheGridViewModal.swift
//  Broche
//
//  Created by Jacob Johnson on 3/25/25.
//

import Foundation

@MainActor
class BrocheGridViewModel: ObservableObject {
    @Published var pinnedPosts: [Post?] = Array(repeating: nil, count: 9)
    private let user: User
    
    init(user: User) {
        self.user = user
        Task { await fetchPinnedPosts() }
    }
    
    func fetchPinnedPosts() async {
        do {
            let fetchedPosts = try await PostService.fetchPinnedPosts(forUserID: user.id)
            pinnedPosts = Array(repeating: nil, count: 9)
            for post in fetchedPosts {
                if let position = post.position, position >= 0, position < 9 {
                    pinnedPosts[position] = post
                }
            }
        } catch {
            print("Error fetching pinned posts: \(error)")
        }
    }
    
    func pinPost(_ post: Post, at position: Int) {
        let slot = position // 0-8 from picker (1-9 in UI)
        guard slot >= 0 && slot < 9 else { return }
        
        // Fetch current state
        Task { await fetchPinnedPosts() }
        
        var updatedPost = post
        updatedPost.position = slot
        
        // Remove old post from this slot in Firebase if it exists
        if let oldPost = pinnedPosts[slot], let oldPostId = oldPost.id, oldPost.id != post.id {
            Task { try await PostService.removePinnedPost(oldPostId, forUserID: user.id) }
            pinnedPosts[slot] = nil
        }
        
        // Remove if already pinned elsewhere
        if let currentIndex = pinnedPosts.firstIndex(where: { $0?.id == post.id }), currentIndex != slot {
            pinnedPosts[currentIndex] = nil
            Task { try await PostService.removePinnedPost(post.id!, forUserID: user.id) }
        }
        
        // Place in the specified slot
        pinnedPosts[slot] = updatedPost
        Task { try await PostService.savePinnedPost(updatedPost, forUserID: user.id) }
    }
    
    func unpinPost(_ post: Post) {
        if let index = pinnedPosts.firstIndex(where: { $0?.id == post.id }), let postId = post.id {
            pinnedPosts[index] = nil
            Task { try await PostService.removePinnedPost(postId, forUserID: user.id) }
        }
    }
}


