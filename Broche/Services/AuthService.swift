//
//  AuthService.swift
//  Broche
//
//  Created by Jacob Johnson on 5/19/23.
//

import Foundation
import FirebaseAuth
import FirebaseFirestoreSwift
import Firebase

class AuthService {
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    static let shared = AuthService()
    
    init() {
        Task { try await loadUserData() }
    }
    
    @MainActor
    func login(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            try await loadUserData()
        } catch {
            print("DEBUG: Failed to log in with error \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func createUser(email: String, password: String, username: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            await uploadUserData(uid: result.user.uid, username: username, email: email)
        } catch {
            print("DEBUG: Failed to register user with error \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func loadUserData() async throws {
        self.userSession = Auth.auth().currentUser
        guard let currentUid = userSession?.uid else {
            print("DEBUG: No user session found")
            self.currentUser = nil
            return
        }
        do {
            self.currentUser = try await UserService.fetchUser(withUid: currentUid)
        } catch {
            print("DEBUG: Failed to load user data: \(error.localizedDescription)")
            self.currentUser = nil
            throw error
        }
    }
    
    func signout() {
        try? Auth.auth().signOut()
        self.userSession = nil
        self.currentUser = nil
    }
    
    private func uploadUserData(uid: String, username: String, email: String) async {
        let user = User(id: uid, username: username, email: email, verificationStatus: .none) // Explicitly set
        self.currentUser = user
        guard let encodedUser = try? Firestore.Encoder().encode(user) else {
            print("DEBUG: Failed to encode user data")
            return
        }
        do {
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
        } catch {
            print("DEBUG: Failed to upload user data: \(error.localizedDescription)")
        }
    }
}

