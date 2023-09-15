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
            if var location = try? document.data(as: Location.self) {
                location.id = document.documentID // Assign the document ID
                return location
            } else {
                print("Error: Failed to decode location document with ID: \(document.documentID)")
                return nil
            }
        }
        return locations
    }

    static func saveLocation(uid: String, coordinate: Location) async throws {
        let collectionRef = COLLECTION_LOCATION.document(uid).collection("user-locations")
        let querySnapshot = try await collectionRef.getDocuments()

        for document in querySnapshot.documents {
            if let location = try? document.data(as: Location.self),
               location.latitude == coordinate.latitude && location.longitude == coordinate.longitude {
                print("Location already saved!")
                return
            }
        }

        let documentRef = collectionRef.document()
        var locationData = try Firestore.Encoder().encode(coordinate)
        locationData["id"] = documentRef.documentID // Add the document ID to the data
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
                
                // Delete comments associated with the location
                let commentsRef = document.reference.collection("location-comments")
                let commentsQuerySnapshot = try await commentsRef.getDocuments()
                
                for commentDocument in commentsQuerySnapshot.documents {
                    try await commentDocument.reference.delete()
                }
                
                print("Location and associated comments unsaved successfully!")
                return
            }
        }

        print("Error: Failed to find and unsave the location.")
    }


    static func checkIfUserSavedLocation(uid: String, coordinate: Location) async throws -> Bool {
        let collectionRef = COLLECTION_LOCATION.document(uid).collection("user-locations")
        let querySnapshot = try await collectionRef.getDocuments()

        for document in querySnapshot.documents {
            if let location = try? document.data(as: Location.self) {
                let latDiff = abs(location.latitude - coordinate.latitude)
                let lonDiff = abs(location.longitude - coordinate.longitude)
                if latDiff < 0.0001 && lonDiff < 0.0001 { // Adjust the threshold as needed
                    print("Location found: \(location)")
                    return true
                }
            }
        }

        print("Location not found!")
        return false
    }
}

extension UserService {

    static func fetchFutureSavedLocations(forUserID uid: String) async throws -> [Location] {
        let collectionRef = COLLECTION_FUTURE_LOCATIONS.document(uid).collection("user-locations")
        let querySnapshot = try await collectionRef.getDocuments()
        let locations = querySnapshot.documents.compactMap { document -> Location? in
            if var location = try? document.data(as: Location.self) {
                location.id = document.documentID // Assign the document ID
                return location
            } else {
                print("Error: Failed to decode future visit location document with ID: \(document.documentID)")
                return nil
            }
        }
        return locations
    }

    static func saveFutureLocation(uid: String, coordinate: Location) async throws {
        let collectionRef = COLLECTION_FUTURE_LOCATIONS.document(uid).collection("user-locations")
        let querySnapshot = try await collectionRef.getDocuments()

        for document in querySnapshot.documents {
            if let location = try? document.data(as: Location.self),
               location.latitude == coordinate.latitude && location.longitude == coordinate.longitude {
                print("Future location already saved!")
                return
            }
        }

        let documentRef = collectionRef.document()
        var locationData = try Firestore.Encoder().encode(coordinate)
        locationData["id"] = documentRef.documentID // Add the document ID to the data
        try await documentRef.setData(locationData)
        print("Future location saved successfully!")
    }

    static func unSaveFutureLocation(uid: String, coordinate: Location) async throws {
        let collectionRef = COLLECTION_FUTURE_LOCATIONS.document(uid).collection("user-locations")
        let querySnapshot = try await collectionRef.getDocuments()

        for document in querySnapshot.documents {
            if let location = try? document.data(as: Location.self),
               location.latitude == coordinate.latitude && location.longitude == coordinate.longitude {
                try await document.reference.delete()
                
                // Delete comments associated with the location
                let commentsRef = document.reference.collection("location-comments")
                let commentsQuerySnapshot = try await commentsRef.getDocuments()
                
                for commentDocument in commentsQuerySnapshot.documents {
                    try await commentDocument.reference.delete()
                }
                
                print("Future location and associated comments unsaved successfully!")
                return
            }
        }

        print("Error: Failed to find and unsave the future location.")
    }


    static func checkIfUserSavedFutureLocation(uid: String, coordinate: Location) async throws -> Bool {
        let collectionRef = COLLECTION_FUTURE_LOCATIONS.document(uid).collection("user-locations")
        let querySnapshot = try await collectionRef.getDocuments()

        for document in querySnapshot.documents {
            if let location = try? document.data(as: Location.self) {
                let latDiff = abs(location.latitude - coordinate.latitude)
                let lonDiff = abs(location.longitude - coordinate.longitude)
                if latDiff < 0.0001 && lonDiff < 0.0001 { // Adjust the threshold as needed
                    print("Future location found: \(location)")
                    return true
                }
            }
        }

        print("Future location not found!")
        return false
    }
}


