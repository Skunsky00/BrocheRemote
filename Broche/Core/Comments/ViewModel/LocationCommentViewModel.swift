//
//  LocationCommentViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 9/8/23.
//

import SwiftUI
import Firebase

@MainActor
class LocationCommentViewModel: ObservableObject {
    private let location: Location
    private let locationId: String
    @Published var comments = [LocationComment]()
    
    init(location: Location) {
        self.location = location
        self.locationId = location.id
        
        Task { try await fetchVisitedComments() }
    }
    
    func uploadVisitedComment(commentText: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let data: [String: Any] = ["commentOwnerUid": uid,
                                   "timestamp": Timestamp(date: Date()),
                                   "locationOwnerUid": location.ownerUid,
                                   "locationId": locationId,
                                   "commentText": commentText]
        
        let _ = try? await COLLECTION_LOCATION.document(locationId).collection("location-comments").addDocument(data: data)
        self.comments.insert(LocationComment(user: currentUser, data: data), at: 0)
    }
    
    func fetchVisitedComments() async throws {
        let query = COLLECTION_LOCATION.document(locationId).collection("location-comments").order(by: "timestamp", descending: true)
        guard let commentSnapshot = try? await query.getDocuments() else { return }
        let documentData = commentSnapshot.documents.compactMap({ $0.data() })
        
        for data in documentData {
            guard let uid = data ["commentOwnerUid"] as? String else { return }
            let user = try await UserService.fetchUser(withUid: uid)
            let comment = LocationComment(user: user, data: data)
            self.comments.append(comment)
        }
    
    }
    
    // Add other functions specific to location comments if needed
}
