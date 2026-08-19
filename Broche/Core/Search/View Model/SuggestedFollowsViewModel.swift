//
//  SuggestedFollowsViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 8/15/26.
//

import Foundation
import Firebase

@MainActor
class SuggestedFollowsViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    private var lastDoc: DocumentSnapshot?
    private var reachedEnd = false

    func loadInitial() async {
        guard users.isEmpty else { return }
        await loadMore()
    }

    func loadMore() async {
        guard !isLoading, !reachedEnd else { return }
        isLoading = true
        do {
            let (newUsers, last) = try await UserService.fetchSuggestedUsers(startingAfter: lastDoc)
            users.append(contentsOf: newUsers)
            lastDoc = last
            if last == nil { reachedEnd = true }
        } catch {
            print("DEBUG: Failed to fetch suggested users: \(error)")
        }
        isLoading = false
    }

    func toggleFollow(_ user: User) {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else { return }
        let wasFollowed = users[index].isFollowed ?? false
        users[index].isFollowed = !wasFollowed

        if wasFollowed {
            UserService.unfollow(uid: user.id) { _ in }
        } else {
            UserService.follow(uid: user.id) { _ in }
        }
    }
}
