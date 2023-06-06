//
//  PostGridViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/23/23.
//

import SwiftUI
import Firebase

enum PostGridConfiguration {
    case explore
    case profile(User)
    case likedPosts(User)
    case bookmarkedPosts(User)
}

class PostGridViewModel: ObservableObject {
    @Published var posts = [Post]()
    private let config: PostGridConfiguration
    private var lastDoc: QueryDocumentSnapshot?
    
    init(config: PostGridConfiguration) {
        self.config = config
        fetchPosts(forConfig: config)
    }
    
    func fetchPosts(forConfig config: PostGridConfiguration) {
        switch config {
        case .explore:
            fetchExplorePagePosts()
        case .profile(let user):
            Task { try await fetchUserPosts(forUser: user) }
        case .likedPosts(let user):
            Task { try await fetchLikedPosts(forUser: user) }
        case .bookmarkedPosts(let user):
            Task { try await fetchBookmarkedPosts(forUser: user) }
        }
    }
    
    func fetchExplorePagePosts() {
        let query = COLLECTION_POSTS.limit(to: 20).order(by: "timestamp", descending: true)
        
        if let last = lastDoc {
            let next = query.start(afterDocument: last)
            next.getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents, !documents.isEmpty else { return }
                self.lastDoc = snapshot?.documents.last
                self.posts.append(contentsOf: documents.compactMap({ try? $0.data(as: Post.self) }))
            }
        } else {
            query.getDocuments { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                self.posts = documents.compactMap({ try? $0.data(as: Post.self) })
                self.lastDoc = snapshot?.documents.last
            }
        }
    }
    
    
    @MainActor
    func fetchUserPosts(forUser user: User) async throws {
        let posts = try await PostService.fetchUserPosts(user: user)
        self.posts = posts
    }
    @MainActor
    func fetchLikedPosts(forUser user: User) async throws {
        let posts = try await PostService.fetchLikedPosts(forUserID: user.id)
        self.posts = posts
    }
    @MainActor
    func fetchBookmarkedPosts(forUser user: User) async throws {
        let posts = try await PostService.fetchBookmarkedPosts(forUserID: user.id)
        self.posts = posts
            
        }
}
//    @MainActor
//    func fetchUserPosts(forUser user: User) async throws {
//        self.posts = try await PostService.fetchUserPosts(uid: user.id)
//
//        for i in 0 ..< posts.count {
//            posts[i].user = self.user
//        }
//    }
//}
