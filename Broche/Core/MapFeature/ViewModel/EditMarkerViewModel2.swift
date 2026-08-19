//
//  EditMarkerViewModel2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import Foundation
import SwiftUI
import Firebase


// Consolidated Edit ViewModel
class EditMarkerViewModel2: ObservableObject {
    @Published var user: User
    @Published var location: Location
    @Published var description: String = ""
    @Published var link: String = ""
    let type: MarkerType
    
    init(user: User, location: Location, type: MarkerType) {
        self.user = user
        self.location = location
        self.type = type
        self.description = location.description ?? ""
        self.link = location.link ?? ""
    }
    
    @MainActor
    func updateUserData() async throws -> Location {
        var data: [String: Any] = [:]
        
        if description != location.description {
            data["description"] = description.isEmpty ? FieldValue.delete() : description
        }
        if type == .visited && link != location.link {
            data["link"] = link.isEmpty ? FieldValue.delete() : link
        }
        
        if !data.isEmpty {
            let collection = type == .visited ? COLLECTION_LOCATION : COLLECTION_FUTURE_LOCATIONS
            let docRef = collection.document(user.id).collection("user-locations").document(location.id)
            try await docRef.updateData(data)
        }
        
        let updated = Location(
            id: location.id,
            ownerUid: location.ownerUid,
            latitude: location.latitude,
            longitude: location.longitude,
            city: location.city,
            date: location.date,
            description: description.isEmpty ? nil : description,
            link: type == .visited ? (link.isEmpty ? nil : link) : location.link,
            createdAt: location.createdAt
        )
        return updated
    }
}
