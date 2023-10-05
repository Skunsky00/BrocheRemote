//
//  EditVisitedViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/23.
//

import Foundation
import SwiftUI
import Firebase

class EditVisitedViewModel: ObservableObject {
    @Published var user: User
    @Published var location: Location
    
    @Published var date = ""
    @Published var description = ""
    @Published var link = ""
    
    init(user: User, location: Location) {
        self.user = user
        self.location = location
        
        if let date = location.date {
            self.date = date
        }
        if let description = location.description {
            self.description = description
        }
        if let link = location.link {
            self.link = link
        }
    }
    
    @MainActor
    func updateUserData() async throws {
        print("Updating user data...")
        var data = [String: Any]()
        
        if !date.isEmpty && location.date != date {
            data["date"] = date
        }
        
        if !description.isEmpty && location.description != description {
            data["description"] = description
        }
        
        if !link.isEmpty && location.link != link {
                data["link"] = link
            } else if link.isEmpty && location.link != nil {
                // Set the link to nil in the database if it's empty
                data["link"] = FieldValue.delete()
            }
        
        if !data.isEmpty {
            // Use the existing `location` instance to update the correct document
            let documentRef = COLLECTION_LOCATION.document(user.id).collection("user-locations").document(location.id)
            try await documentRef.updateData(data)
            print("Data updated successfully!")
        }
    }
}
