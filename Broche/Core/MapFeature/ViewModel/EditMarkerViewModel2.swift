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
    @Published var date: String = ""
    @Published var description: String = ""
    @Published var link: String = ""
    let type: MarkerType
    
    init(user: User, location: Location, type: MarkerType) {
        self.user = user
        self.location = location
        self.type = type
        self.date = location.date ?? ""
        self.description = location.description ?? ""
        self.link = location.link ?? ""
    }
    
    @MainActor
    func updateUserData() async throws {
        var data: [String: Any] = [:]
        
        if date != location.date {
            data["date"] = date.isEmpty ? FieldValue.delete() : date
        }
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
    }
}
