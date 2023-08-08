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
    
    init(user: User) {
            self.user = user
            self.location = user.location ?? Location(documentID: "", latitude: 0, longitude: 0)
        
        if let date = user.location?.date {
            self.date = date
        }
        if let description = user.location?.description {
            self.description = description
        }
    }
    
    @MainActor
        func fetchSelectedLocationDocument() async throws -> DocumentSnapshot? {
            let selectedLocation = location // Get the selected location
            
            // Fetch the document from Firestore
            do {
                let querySnapshot = try await COLLECTION_FUTURE_LOCATIONS.document(user.id).collection("user-locations").whereField("latitude", isEqualTo: selectedLocation.latitude).whereField("longitude", isEqualTo: selectedLocation.longitude).getDocuments()
                
                // There should be only one document that matches the selected location
                if let document = querySnapshot.documents.first {
                    return document
                }
            } catch {
                print("Error fetching selected location document: \(error.localizedDescription)")
                throw error
            }
            
            return nil
        }

        @MainActor
        func updateUserDataForSelectedLocation() async throws {
            do {
                // Fetch the selected location's document
                if let selectedLocationDocument = try await fetchSelectedLocationDocument() {
                    var data = [String: Any]()
                    
                    if !date.isEmpty && selectedLocationDocument["date"] as? String != date {
                        data["date"] = date
                    }
                    
                    if !description.isEmpty && selectedLocationDocument["description"] as? String != description {
                        data["description"] = description
                    }
                    
                    if !data.isEmpty {
                        // Update the document in Firestore
                        try await selectedLocationDocument.reference.updateData(data)
                        print("Data updated successfully!")
                    }
                } else {
                    print("Selected location document not found.")
                }
            } catch {
                print("Error updating user data: \(error.localizedDescription)")
                throw error
            }
        }
    }
    

