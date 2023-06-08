//
//  User Service.swift
//  Broche
//
//  Created by Jacob Johnson on 5/22/23.
//

import Foundation
import Firebase
import MapKit

struct UserService {
    
    static func follow(uid: String, completion: ((Error?) -> Void)?) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_FOLLOWING.document(currentUid)
            .collection("user-following").document(uid).setData([:]) { _ in
                COLLECTION_FOLLOWERS.document(uid).collection("user-followers")
                    .document(currentUid).setData([:], completion: completion)
            }
    }
    
    static func unfollow(uid: String, completion: ((Error?) -> Void)?) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }

        COLLECTION_FOLLOWING.document(currentUid).collection("user-following")
            .document(uid).delete { _ in
                COLLECTION_FOLLOWERS.document(uid).collection("user-followers")
                    .document(currentUid).delete(completion: completion)
            }
    }
    
    static func checkIfUserIsFollowed(uid: String) async -> Bool {
        guard let currentUid = Auth.auth().currentUser?.uid else { return false }
        let collection = COLLECTION_FOLLOWING.document(currentUid).collection("user-following")
        guard let snapshot = try? await collection.document(uid).getDocument() else { return false }
        return snapshot.exists
    }
    
    
    
    
    
    
    
    static func fetchUser(wtihUid uid: String) async throws -> User {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }
    
    static func fetchUserPosts(user: User) async throws -> [Post] {
        let snapshot = try await COLLECTION_POSTS.whereField("ownerUid", isEqualTo: user.id).getDocuments()
        var posts = snapshot.documents.compactMap({try? $0.data(as: Post.self )})
        
        for i in 0 ..< posts.count {
            posts[i].user = user
        }
        
        return posts
    }

    
    static func fetchAllUsers() async throws -> [User] {
        let snapshot = try await Firestore.firestore().collection("users").getDocuments()
        return snapshot.documents.compactMap({ try? $0.data(as: User.self) })
    }
}

extension UserService {
    static func fetchSavedLocations(uid: String) async throws -> [Location] {
            let collectionRef = COLLECTION_LOCATION.document(uid).collection("user-locations")
            let querySnapshot = try await collectionRef.getDocuments()
            let locations = querySnapshot.documents.compactMap { document -> Location? in
                if let location = try? document.data(as: Location.self) {
                    return location
                } else {
                    print("Error: Failed to decode location document with ID: \(document.documentID)")
                    return nil
                }
            }
            return locations
        }
    
    
    static func saveLocation(uid: String, coordinate: Location) async throws {
        let documentRef = COLLECTION_LOCATION.document(uid).collection("user-locations").document()
        let locationData = try Firestore.Encoder().encode(coordinate)
        try await documentRef.setData(locationData)
        print("Location saved successfully!")
    }
            
            
    
    static func unSaveLocation(uid: String) async throws  {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
                    print("Error: User is not authenticated.")
                    return
                }
        let documentRef = COLLECTION_LOCATION.document(currentUserID).collection("user-locations").document(uid)
                try await documentRef.delete()

    }
    
    static func checkIfUserSavedLocation(uid: String) async -> Bool {
        guard let currentUid = Auth.auth().currentUser?.uid else { return false }
        let collection = COLLECTION_LOCATION.document(currentUid).collection("user-locations")
        guard let snapshot = try? await collection.document(uid).getDocument() else { return false }
        return snapshot.exists
    
    }
}


