//
//  ProfileViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/30/23.
//

import SwiftUI
import FirebaseAuth

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var followsMe: Bool = false   // NEW
    
    init(user: User) {
        self.user = user
        loadUserData()
    }
    
    func follow() {
            UserService.follow(uid: user.id) { _ in
                NotificationService.uploadNotification(toUid: self.user.id, type: .follow)
                self.user.isFollowed = true
                self.user.stats?.followers = (self.user.stats?.followers ?? 0) + 1   // NEW
            }
        }
        
        func unfollow() {
            UserService.unfollow(uid: user.id) { _ in
                self.user.isFollowed = false
                self.user.stats?.followers = max((self.user.stats?.followers ?? 1) - 1, 0)   // NEW
                NotificationService.deleteNotification(toUid: self.user.id, type: .follow)
            }
        }
    
    func checkIfUserIsFollowed() async -> Bool {
        guard !user.isCurrentUser else { return false }
        return await UserService.checkIfUserIsFollowed(uid: user.id)
    }
    
    // NEW — checks the reverse relationship: does THIS person follow ME
        func checkIfUserFollowsMe() async -> Bool {
            guard !user.isCurrentUser, let currentUid = Auth.auth().currentUser?.uid else { return false }
            return await UserService.checkIfUserIsFollowed(uid: currentUid, byUid: user.id)
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
            
            async let followsMe = await checkIfUserFollowsMe()   // NEW
            self.followsMe = await followsMe
        }
    }
    
    func updateUserData(user: User) {
        self.user = user
        loadUserData() // Reload the user's data with the updated user instance
    }
}
