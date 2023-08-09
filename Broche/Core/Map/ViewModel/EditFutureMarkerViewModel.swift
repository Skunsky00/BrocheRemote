//
//  EditFutureMarkerViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 8/4/23.
//

import Foundation
import SwiftUI
import Firebase

@MainActor
class EditFutureMarkerViewModel: ObservableObject {
    @Published var user: User
    @Published var location: Location
    
    @Published var date = ""
    @Published var description = ""
    
    init(user: User, location: Location) {
        self.user = user
        self.location = location
        
        if let date = location.date {
            self.date = date
        }
        if let description = location.description {
            self.description = description
        }
    }
    
    @MainActor
    func updateUserData() async throws {
        var data = [String: Any]()
        
        if !date.isEmpty && location.date != date {
            data["date"] = date
        }
        
        if !description.isEmpty && location.description != description {
            data["description"] = description
        }
        
        if !data.isEmpty {
            // Use the existing `location` instance to update the correct document
            let documentRef = COLLECTION_FUTURE_LOCATIONS.document(user.id).collection("user-locations").document(location.id!)
            try await documentRef.updateData(data)
            print("Data updated successfully!")
        }
    }
}
    

