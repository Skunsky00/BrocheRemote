//
//  User Service.swift
//  Broche
//
//  Created by Jacob Johnson on 5/22/23.
//

import Foundation
import Firebase

struct UserService {
    
    static func fetchUser(wtihUid uid: String) async throws -> User {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }
    
    static func fetchAllUsers() async throws -> [User] {
        let snapshot = try await Firestore.firestore().collection("users").getDocuments()
        return snapshot.documents.compactMap({ try? $0.data(as: User.self) })
    }
}
