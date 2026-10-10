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
            self.user.followersCount = (self.user.followersCount ?? 0) + 1   // CHANGED
        }
    }

    func unfollow() {
        UserService.unfollow(uid: user.id) { _ in
            self.user.isFollowed = false
            self.user.followersCount = max((self.user.followersCount ?? 1) - 1, 0)   // CHANGED
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


    func loadUserData() {
        Task {
            async let isFollowed = checkIfUserIsFollowed()
            async let followsMe = checkIfUserFollowsMe()

            self.user.isFollowed = await isFollowed
            self.followsMe = await followsMe
        }
    }
    
    func updateUserData(user: User) {
        self.user = user
        loadUserData() // Reload the user's data with the updated user instance
    }
}
