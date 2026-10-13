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
        UserService.follow(uid: user.id) { [weak self] error in
            guard let self, error == nil else { return }
            NotificationService.uploadNotification(toUid: self.user.id, type: .follow)
            self.user.isFollowed = true
            Task { await self.refreshCounts() }
        }
    }

    func unfollow() {
        UserService.unfollow(uid: user.id) { [weak self] error in
            guard let self, error == nil else { return }
            NotificationService.deleteNotification(toUid: self.user.id, type: .follow)
            self.user.isFollowed = false
            Task { await self.refreshCounts() }
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


    func loadUserData() {
        Task {
            async let isFollowed = checkIfUserIsFollowed()
            async let followsMe = checkIfUserFollowsMe()

            await refreshCounts()
            self.user.isFollowed = await isFollowed
            self.followsMe = await followsMe
        }
    }

    // Pulls fresh counts from Firestore; self-heals if the fields don't exist yet
    func refreshCounts() async {
        guard var fresh = try? await UserService.fetchUser(withUid: user.id) else { return }

        if fresh.followersCount == nil || fresh.followingCount == nil {
            await UserService.recalculateCounts(uid: user.id)
            if let healed = try? await UserService.fetchUser(withUid: user.id) { fresh = healed }
        }

        self.user.followersCount = fresh.followersCount ?? 0
        self.user.followingCount = fresh.followingCount ?? 0
    }
    
    func updateUserData(user: User) {
        self.user = user
        loadUserData() // Reload the user's data with the updated user instance
    }
}
