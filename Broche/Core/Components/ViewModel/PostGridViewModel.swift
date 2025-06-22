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
    case collectionPosts(userId: String, collectionId: String)
}

class PostGridViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
    private let config: PostGridConfiguration
    private var lastDoc: QueryDocumentSnapshot?
    
    init(config: PostGridConfiguration) {
        self.config = config
        fetchPosts(forConfig: config)
    }
    
    func fetchPosts(forConfig config: PostGridConfiguration) {
        isLoading = true
        switch config {
        case .explore:
            Task { await fetchExplorePagePosts() }
        case .profile(let user):
            Task { try await fetchUserPosts(forUser: user) }
        case .likedPosts(let user):
            Task { try await fetchLikedPosts(forUser: user) }
        case .bookmarkedPosts(let user):
            Task { try await fetchBookmarkedPosts(forUser: user) }
        case .collectionPosts(let userId, let collectionId):
            Task { try await fetchCollectionPosts(userId: userId, collectionId: collectionId) }
        }
    }
    
    @MainActor
    func fetchExplorePagePosts() async {
        let query = Firestore.firestore().collection("posts").limit(to: 20).order(by: "timestamp", descending: true)
        do {
            if let last = lastDoc {
                let next = query.start(afterDocument: last)
                let snapshot = try await next.getDocuments()
                if !snapshot.documents.isEmpty {
                    self.lastDoc = snapshot.documents.last
                    self.posts.append(contentsOf: snapshot.documents.compactMap { try? $0.data(as: Post.self) })
                }
            } else {
                let snapshot = try await query.getDocuments()
                if !snapshot.documents.isEmpty {
                    self.posts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
                    self.lastDoc = snapshot.documents.last
                }
            }
        } catch {
            print("Error fetching explore page posts: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func fetchUserPosts(forUser user: User) async throws {
        let posts = try await PostService.fetchUserPosts(user: user)
        self.posts = posts
        isLoading = false
    }
    
    @MainActor
    func fetchLikedPosts(forUser user: User) async throws {
        let posts = try await PostService.fetchLikedPosts(forUserID: user.id)
        self.posts = posts
        isLoading = false
    }
    
    @MainActor
    func fetchBookmarkedPosts(forUser user: User) async throws {
        let posts = try await PostService.fetchBookmarkedPosts(forUserID: user.id)
        self.posts = posts
        isLoading = false
    }
    
    @MainActor
    func fetchCollectionPosts(userId: String, collectionId: String) async throws {
        let posts = try await PostService.fetchPostsInCollection(userId: userId, collectionId: collectionId)
        self.posts = posts
        isLoading = false
    }
    
    func filteredPosts(_ query: String) -> [Post] {
        let lowercasedQuery = query.lowercased()
        return posts.filter {
            $0.location.lowercased().contains(lowercasedQuery) ||
            ($0.label?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    func refresh() {
        fetchPosts(forConfig: config)
    }
}
