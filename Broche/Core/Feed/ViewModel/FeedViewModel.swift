//
//  FeedViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/23/23.
//

import Foundation
import Firebase

class FeedViewModel: ObservableObject {
    @Published var posts = [Post]()
    @Published var lastDocument: DocumentSnapshot?
    
    @MainActor
    init() {
        Task {lastDocument = nil // Reset lastDocument to fetch the most recent posts
                try await fetchPosts()}
        
    }
    
    @MainActor
    func fetchPosts() async throws {
        let (posts, lastDocument) = try await PostService.fetchPosts(startingAfter: lastDocument)
        self.posts.append(contentsOf: posts)
        self.lastDocument = lastDocument // Update lastDocument with the returned value
    }
    
    func fetchMorePosts() async throws {
        try await fetchPosts()
    }
}
