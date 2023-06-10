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

    
    static func fetchUser(withUid uid: String) async throws -> User {
        let snapshot = try await COLLECTION_USERS.document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }

    
    static func fetchAllUsers() async throws -> [User] {
        let snapshot = try await COLLECTION_USERS.getDocuments()
        return snapshot.documents.compactMap({ try? $0.data(as: User.self) })
    }
}

extension UserService {
    static func fetchSavedLocations(forUserID uid: String) async throws -> [Location] {
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
            
            
    
    static func unSaveLocation(uid: String, coordinate: Location) async throws {
        let collectionRef = COLLECTION_LOCATION.document(uid).collection("user-locations")
        let querySnapshot = try await collectionRef.getDocuments()
        
        for document in querySnapshot.documents {
            if let location = try? document.data(as: Location.self),
               location.latitude == coordinate.latitude && location.longitude == coordinate.longitude {
                try await document.reference.delete()
                print("Location unsaved successfully!")
                return
            }
        }
        
        print("Error: Failed to find and unsave the location.")
    }
    
    static func checkIfUserSavedLocation(uid: String, coordinate: Location) async -> Bool {
        guard let currentUid = Auth.auth().currentUser?.uid else { return false }
        let collection = COLLECTION_LOCATION.document(currentUid).collection("user-locations")
        guard let snapshot = try? await collection.document(uid).getDocument() else { return false }
        return snapshot.exists
    
    }
}


