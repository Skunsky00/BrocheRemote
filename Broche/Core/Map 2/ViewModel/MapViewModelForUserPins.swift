//
//  MapViewModelForUserPins.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI
import _MapKit_SwiftUI
import Firebase
import FirebaseFirestore
import CoreLocation

@MainActor
class MapViewModelForUserPins: ObservableObject {
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var visitedLocations: [Location] = []
    @Published var futureLocations: [Location] = []
    
    func updateCameraPosition(_ userLocation: CLLocation?) {
        if let userLoc = userLocation {
            cameraPosition = .region(MKCoordinateRegion(
                center: userLoc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    func fetchLocations(userId: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                visitedLocations = try await UserService.fetchSavedLocations(forUserID: userId, type: .visited)
                futureLocations = try await UserService.fetchSavedLocations(forUserID: userId, type: .future)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
