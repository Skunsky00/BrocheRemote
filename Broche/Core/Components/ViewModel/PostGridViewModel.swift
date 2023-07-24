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
            Task { await fetchExplorePagePosts() }
        case .profile(let user):
            Task { try await fetchUserPosts(forUser: user) }
        case .likedPosts(let user):
            Task { try await fetchLikedPosts(forUser: user) }
        case .bookmarkedPosts(let user):
            Task { try await fetchBookmarkedPosts(forUser: user) }
        }
    }
    @MainActor
    func fetchExplorePagePosts() async {
        let query = COLLECTION_POSTS.limit(to: 20).order(by: "timestamp", descending: true)

        do {
            if let last = lastDoc {
                let next = query.start(afterDocument: last)
                let snapshot = try await next.getDocuments()
                if !snapshot.documents.isEmpty {
                    self.lastDoc = snapshot.documents.last
                    self.posts.append(contentsOf: snapshot.documents.compactMap({ try? $0.data(as: Post.self) }))
                }
            } else {
                let snapshot = try await query.getDocuments()
                if !snapshot.documents.isEmpty {
                    self.posts = snapshot.documents.compactMap({ try? $0.data(as: Post.self) })
                    self.lastDoc = snapshot.documents.last
                }
            }
        } catch {
            print("Error fetching explore page posts: \(error)")
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
    
    func filteredPosts(_ query: String) -> [Post] {
        let lowercasedQuery = query.lowercased()
        return posts.filter({
            $0.location.lowercased().contains(lowercasedQuery) ||
            ($0.label?.lowercased().contains(lowercasedQuery) ?? false)
        })
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
