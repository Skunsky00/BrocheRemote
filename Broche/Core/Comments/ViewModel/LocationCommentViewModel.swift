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
    private let locationType: MarkerType
    @Published var comments = [LocationComment]()

    init(location: Location, locationType: MarkerType) {
        self.location = location
        self.locationId = location.id
        self.locationType = locationType
        Task { try await fetchComments() }
    }

    private func collectionRef() -> CollectionReference {   // NEW — de-dupes the repeated switch
        switch locationType {
        case .visited:
            return COLLECTION_LOCATION.document(location.ownerUid).collection("user-locations").document(locationId).collection("location-comments")
        case .future:
            return COLLECTION_FUTURE_LOCATIONS.document(location.ownerUid).collection("user-locations").document(locationId).collection("location-comments")
        }
    }

    func uploadVisitedComment(commentText: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let currentUser = AuthService.shared.currentUser else { return }

        let data: [String: Any] = [
            "commentOwnerUid": uid,
            "timestamp": Timestamp(date: Date()),
            "locationOwnerUid": location.ownerUid,
            "locationId": locationId,
            "commentText": commentText,
            "city": location.city ?? "",
            "likes": [String]()   // NEW
        ]

        guard let ref = try? await collectionRef().addDocument(data: data) else { return }
        NotificationService.uploadNotification(toUid: self.location.ownerUid, type: .locationComment, location: self.location)
        self.comments.insert(LocationComment(id: ref.documentID, user: currentUser, data: data), at: 0)   // CHANGED
    }

    func fetchComments() async throws {
        let query = collectionRef().order(by: "timestamp", descending: true)
        guard let commentSnapshot = try? await query.getDocuments() else { return }

        for doc in commentSnapshot.documents {   // CHANGED
            let data = doc.data()
            guard let uid = data["commentOwnerUid"] as? String else { continue }
            let user = try await UserService.fetchUser(withUid: uid)
            let comment = LocationComment(id: doc.documentID, user: user, data: data)   // CHANGED
            self.comments.append(comment)
        }
    }

    // NEW
    func toggleLike(_ comment: LocationComment) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }

        let ref = collectionRef().document(comment.id)

        if comment.didLike(uid: uid) {
            comments[index].likes.removeAll { $0 == uid }
            try? await ref.updateData(["likes": FieldValue.arrayRemove([uid])])
        } else {
            comments[index].likes.append(uid)
            try? await ref.updateData(["likes": FieldValue.arrayUnion([uid])])
        }
    }
}
