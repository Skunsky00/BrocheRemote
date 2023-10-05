//
//  ProfileViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/30/23.
//

import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User
    
    init(user: User) {
        self.user = user
        loadUserData()
    }
    
    func follow() {
        UserService.follow(uid: user.id) { _ in
            NotificationsViewModel.uploadNotification(toUid: self.user.id, type: .follow)
            self.user.isFollowed = true
        }
    }
    
    func unfollow() {
        UserService.unfollow(uid: user.id) { _ in
            self.user.isFollowed = false
            NotificationsViewModel.deleteNotification(toUid: self.user.id, type: .follow)
        }
    }
    
    func checkIfUserIsFollowed() async -> Bool {
        guard !user.isCurrentUser else { return false }
        return await UserService.checkIfUserIsFollowed(uid: user.id)
    }
    
    func fetchUserStats() async throws -> UserStats{
        let uid = user.id

        async let followingSnapshot = try await COLLECTION_FOLLOWING.document(uid).collection("user-following").getDocuments()
        let following = try await followingSnapshot.count

        async let followerSnapshot = try await COLLECTION_FOLLOWERS.document(uid).collection("user-followers").getDocuments()
        let followers = try await followerSnapshot.count


        return .init(following: following, followers: followers)
    }

    func loadUserData() {
        Task {
            async let stats = try await fetchUserStats()
            self.user.stats = try await stats

            async let isFollowed = await checkIfUserIsFollowed()
            self.user.isFollowed = await isFollowed
        }
    }
    
    func updateUserData(user: User) {
        self.user = user
        loadUserData() // Reload the user's data with the updated user instance
    }
}
