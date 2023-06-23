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
    private var lastDocument: DocumentSnapshot?
    
    init() {
        Task { try await fetchPosts() }
    }
    
    @MainActor
       func fetchPosts() async throws {
           let posts = try await PostService.fetchPosts(startingAfter: lastDocument)
           self.posts.append(contentsOf: posts)
       }
       
       func fetchMorePosts() async throws {
           try await fetchPosts()
       }
   }
