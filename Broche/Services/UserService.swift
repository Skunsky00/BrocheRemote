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
    
    static func checkIfUserIsFollowed(uid: String, byUid: String) async -> Bool {
            let collection = COLLECTION_FOLLOWING.document(byUid).collection("user-following")
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
    static func fetchSuggestedUsers(startingAfter document: DocumentSnapshot?) async throws -> ([User], DocumentSnapshot?) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return ([], nil) }

        var query = COLLECTION_USERS.order(by: "username").limit(to: 20)
        if let document = document {
            query = COLLECTION_USERS.order(by: "username").start(afterDocument: document).limit(to: 20)
        }

        let snapshot = try await query.getDocuments()
        var users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
        users.removeAll { $0.id == currentUid }

        for i in 0..<users.count {
            users[i].isFollowed = await checkIfUserIsFollowed(uid: users[i].id)
        }

        // filter out already-followed users from the suggestion list
        users.removeAll { $0.isFollowed == true }

        let lastDocument = snapshot.documents.last
        return (users, lastDocument)
    }
}


// UserService extension updated to use Location and fix collection path
extension UserService {
    static func fetchSavedLocations(forUserID uid: String, type: MarkerType) async throws -> [Location] {
        let collectionPath = "user-locations"
        let collectionRef = (type == .visited ? COLLECTION_LOCATION : COLLECTION_FUTURE_LOCATIONS).document(uid).collection(collectionPath)
        let querySnapshot = try await collectionRef.getDocuments()
        let locations = querySnapshot.documents.compactMap { document -> Location? in
            do {
                var location = try document.data(as: Location.self)
                location.id = document.documentID // Assign document ID to location
                return location
            } catch {
                print("Error: Failed to decode \(type) location document with ID: \(document.documentID), error: \(error)")
                return nil
            }
        }
        print("Fetched \(locations.count) \(type) locations for user \(uid): \(locations)")
        return locations
    }
    
    static func saveLocation(uid: String, location: Location, type: MarkerType) async throws -> Location {
        let collection = type == .visited ? COLLECTION_LOCATION : COLLECTION_FUTURE_LOCATIONS
        let subCollection = collection.document(uid).collection("user-locations")
        let querySnapshot = try await subCollection.getDocuments()
        
        for document in querySnapshot.documents {
            if let existingLocation = try? document.data(as: Location.self),
               existingLocation.latitude == location.latitude && existingLocation.longitude == location.longitude {
                print("Location already saved for \(type): \(location)")
                return existingLocation
            }
        }
        
        let docRef = subCollection.document()
        var data = try Firestore.Encoder().encode(location)
        data["id"] = docRef.documentID
        try await docRef.setData(data)
        
        var saved = location
        saved.id = docRef.documentID
        
        if type == .visited {
            Task {
                await NotificationService.uploadNewPinNotificationToFollowers(currentUid: uid, location: saved)
            }
        }
        
        print("Saved \(type) location: \(saved)")
        return saved
    }
    
    static func unSaveLocation(uid: String, location: Location, type: MarkerType) async throws {
        let collection = type == .visited ? COLLECTION_LOCATION : COLLECTION_FUTURE_LOCATIONS
        let subCollection = collection.document(uid).collection("user-locations")
        let querySnapshot = try await subCollection.getDocuments()
        
        for document in querySnapshot.documents {
            if let existingLocation = try? document.data(as: Location.self),
               existingLocation.latitude == location.latitude && existingLocation.longitude == location.longitude {
                
                // NEW — delete all visits (and their posts) under this pin before deleting the pin
                if type == .visited {
                    let visitsSnapshot = try await document.reference.collection("visits").getDocuments()
                    for visitDoc in visitsSnapshot.documents {
                        try await VisitService.deleteVisit(userId: uid, locationId: document.documentID, visitId: visitDoc.documentID)
                    }
                }
                
                try await document.reference.delete()
                
                let commentsRef = document.reference.collection("location-comments")
                let commentsDocs = try await commentsRef.getDocuments().documents
                for commentDoc in commentsDocs {
                    try await commentDoc.reference.delete()
                }
                
                print("Unsaved \(type) location and associated comments: \(location)")
                return
            }
        }
        
        print("No matching \(type) location to unsave: \(location)")
    }
    
    static func checkIfSavedLocation(uid: String, coordinate: CLLocationCoordinate2D, type: MarkerType) async throws -> Bool {
        let collection = type == .visited ? COLLECTION_LOCATION : COLLECTION_FUTURE_LOCATIONS
        let subCollection = collection.document(uid).collection("user-locations")
        let querySnapshot = try await subCollection.getDocuments()
        
        for document in querySnapshot.documents {
            if let location = try? document.data(as: Location.self),
               abs(location.latitude - coordinate.latitude) < 0.0001,
               abs(location.longitude - coordinate.longitude) < 0.0001 {
                print("Found saved \(type) location: \(location)")
                return true
            }
        }
        
        print("No saved \(type) location at: \(coordinate)")
        return false
    }
}


extension UserService {
    static func fetchFriendsWhoVisited(coordinate: CLLocationCoordinate2D) async -> [User] {
            guard let currentUid = Auth.auth().currentUser?.uid else { return [] }
            
            guard let followingSnapshot = try? await COLLECTION_FOLLOWING
                .document(currentUid)
                .collection("user-following")
                .getDocuments() else { return [] }
            
            let followingUids = followingSnapshot.documents.map { $0.documentID }
            guard !followingUids.isEmpty else { return [] }
            
            var matchedUsers: [User] = []
            
            for uid in followingUids {
                let subCollection = COLLECTION_LOCATION.document(uid).collection("user-locations")
                guard let snapshot = try? await subCollection.getDocuments() else { continue }
                
                let hasNearbyVisit = snapshot.documents.contains { doc in
                    guard let location = try? doc.data(as: Location.self) else { return false }
                    return abs(location.latitude - coordinate.latitude) < 0.01 &&
                           abs(location.longitude - coordinate.longitude) < 0.01
                }
                
                if hasNearbyVisit, let user = try? await UserService.fetchUser(withUid: uid) {
                    matchedUsers.append(user)
                }
            }
            
            return matchedUsers
        }
    
    static func fetchLocationId(uid: String, coordinate: CLLocationCoordinate2D, type: MarkerType) async -> String? {
            let collection = type == .visited ? COLLECTION_LOCATION : COLLECTION_FUTURE_LOCATIONS
            let subCollection = collection.document(uid).collection("user-locations")
            guard let querySnapshot = try? await subCollection.getDocuments() else { return nil }
            
            for document in querySnapshot.documents {
                if let location = try? document.data(as: Location.self),
                   abs(location.latitude - coordinate.latitude) < 0.0001,
                   abs(location.longitude - coordinate.longitude) < 0.0001 {
                    return document.documentID
                }
            }
            return nil
        }
    
    static func migrateFutureToVisited(uid: String, location: Location) async throws -> Location {
            let saved = try await saveLocation(uid: uid, location: location, type: .visited)
            try await unSaveLocation(uid: uid, location: location, type: .future)
            return saved
        }
}
