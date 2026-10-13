//
//  PostGridViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/23/23.
//

import SwiftUI
import Firebase

enum PostGridConfiguration {
    case profile(User)
    case likedPosts(User)
    case bookmarkedPosts(User)
    case collectionPosts(userId: String, collectionId: String)
    case visit(Visit)
    case location(Location)
}

@MainActor
final class PostGridViewModel: ObservableObject {
    typealias PageLoader = (DocumentSnapshot?) async throws -> ([Post], DocumentSnapshot?)

    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading = false

    private let loader: PageLoader
    private var lastDoc: DocumentSnapshot?
    private var reachedEnd = false
    private var hasLoadedOnce = false
    private var task: Task<Void, Never>?

    init(loader: @escaping PageLoader) { self.loader = loader }
    deinit { task?.cancel() }

    /// Call from .task / onAppear. Does nothing if we already have data.
    func loadIfNeeded() {
        guard !hasLoadedOnce else { return }
        loadMore()
    }

    func loadMore() {
        guard !isLoading, !reachedEnd else { return }
        isLoading = true
        let cursor = lastDoc
        let loader = self.loader
        task = Task { [weak self] in
            do {
                let (newPosts, last) = try await loader(cursor)
                guard let self, !Task.isCancelled else { return }
                let existing = Set(self.posts.compactMap(\.id))
                self.posts += newPosts.filter { !existing.contains($0.id ?? "") }
                self.lastDoc = last
                if newPosts.isEmpty || last == nil { self.reachedEnd = true }
                self.hasLoadedOnce = true
                self.isLoading = false
            } catch {
                self?.isLoading = false
            }
        }
    }

    /// Call from each cell's onAppear.
    func loadMoreIfNeeded(current post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }),
              index >= posts.count - 6 else { return }
        loadMore()
    }

    /// Pull-to-refresh: reset and reload.
    func refresh() {
        task?.cancel()
        lastDoc = nil
        reachedEnd = false
        hasLoadedOnce = false
        isLoading = false
        posts = []
        loadMore()
    }

    func filteredPosts(_ query: String) -> [Post] {
        let q = query.lowercased()
        return posts.filter { $0.location.lowercased().contains(q) }
    }
}
