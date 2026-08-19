//
//  VisitService.swift
//  Broche
//
//  Created by Jacob Johnson on 8/15/26.
//

import Firebase
import FirebaseFirestore

struct VisitService {
    static func createVisit(ownerUid: String, locationId: String, name: String) async throws -> Visit {
        let visitId = UUID().uuidString
        let visit = Visit(id: visitId, ownerUid: ownerUid, locationId: locationId, name: name)

        let ref = COLLECTION_LOCATION
            .document(ownerUid)
            .collection("user-locations")
            .document(locationId)
            .collection("visits")
            .document(visitId)

        try ref.setData(from: visit)
        return visit
    }

    static func fetchVisits(forUserID userId: String, locationId: String) async throws -> [Visit] {
        let snapshot = try await COLLECTION_LOCATION
            .document(userId)
            .collection("user-locations")
            .document(locationId)
            .collection("visits")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Visit.self) }
    }

    static func updateVisit(_ visit: Visit) async throws {
        let ref = COLLECTION_LOCATION
            .document(visit.ownerUid)
            .collection("user-locations")
            .document(visit.locationId)
            .collection("visits")
            .document(visit.id)

        try ref.setData(from: visit, merge: true)
    }

        static func deleteVisit(userId: String, locationId: String, visitId: String) async throws {
            // 1. Delete all posts belonging to this visit
            let postsSnapshot = try await COLLECTION_POSTS
                .whereField("visitId", isEqualTo: visitId)
                .getDocuments()
            
            for doc in postsSnapshot.documents {
                try await doc.reference.delete()
            }
            
            // 2. Delete the visit document itself
            let ref = COLLECTION_LOCATION
                .document(userId)
                .collection("user-locations")
                .document(locationId)
                .collection("visits")
                .document(visitId)
            
            try await ref.delete()
    }
}
