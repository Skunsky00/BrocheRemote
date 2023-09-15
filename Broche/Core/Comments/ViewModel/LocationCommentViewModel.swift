//
//  LocationCommentViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 9/8/23.
//

import SwiftUI
import Firebase

enum LocationType {
    case visited
    case future
}

@MainActor
class LocationCommentViewModel: ObservableObject {
    private let location: Location
    private let locationId: String
    private let locationType: LocationType
    @Published var comments = [LocationComment]()
    
    init(location: Location, locationType: LocationType) {
        self.location = location
        self.locationId = location.id
        self.locationType = locationType
        
        Task { try await fetchComments() }
    }
    
    func uploadVisitedComment(commentText: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let currentUser = AuthService.shared.currentUser else { return }
        let collectionRef: CollectionReference
                switch locationType {
                case .visited:
                    collectionRef = COLLECTION_LOCATION.document(location.ownerUid).collection("user-locations").document(locationId).collection("location-comments")
                case .future:
                    collectionRef = COLLECTION_FUTURE_LOCATIONS.document(location.ownerUid).collection("user-locations").document(locationId).collection("location-comments")
                }
        
        let data: [String: Any] = ["commentOwnerUid": uid,
                                   "timestamp": Timestamp(date: Date()),
                                   "locationOwnerUid": location.ownerUid,
                                   "locationId": locationId,
                                   "commentText": commentText]
        
        let _ = try? await collectionRef.addDocument(data: data)
        self.comments.insert(LocationComment(user: currentUser, data: data), at: 0)
    }
    
    func fetchComments() async throws {
        let collectionRef: CollectionReference
        switch locationType {
        case .visited:
            collectionRef = COLLECTION_LOCATION.document(location.ownerUid).collection("user-locations").document(locationId).collection("location-comments")
        case .future:
            collectionRef = COLLECTION_FUTURE_LOCATIONS.document(location.ownerUid).collection("user-locations").document(locationId).collection("location-comments")
        }

        let query = collectionRef.order(by: "timestamp", descending: true)

        guard let commentSnapshot = try? await query.getDocuments() else { return }
        let documentData = commentSnapshot.documents.compactMap({ $0.data() })

        for data in documentData {
            guard let uid = data["commentOwnerUid"] as? String else { return }
            let user = try await UserService.fetchUser(withUid: uid)
            let comment = LocationComment(user: user, data: data)
            self.comments.append(comment)
        }
    }

    
    // Add other functions specific to location comments if needed
}
