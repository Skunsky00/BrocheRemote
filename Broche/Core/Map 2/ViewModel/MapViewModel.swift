//
//  MapViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI
import _MapKit_SwiftUI
import Combine
import Firebase
import FirebaseFirestore
import CoreLocation

@MainActor
final class MapViewModel: ObservableObject {

    @Published var mapState: MapViewState2 = .noInput
    @Published var locationViewModel = LocationSearchViewModel2()
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
            span: MKCoordinateSpan(latitudeDelta: 70, longitudeDelta: 70)
        )
    )

    @Published var visitedLocations: [Location] = []
    @Published var futureLocations: [Location] = []
    @Published var didSaveLocation = false
    @Published var didSaveFutureLocation = false
    @Published var showVisitedPins = true
    @Published var showFuturePins = true

    private var cancellables = Set<AnyCancellable>()

    
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
    
    func handleMapStateChange(_ newState: MapViewState2, userId: String, completion: @escaping (Error?) -> Void) {
        guard newState == .locationSelected,
              let coord = locationViewModel.selectedLocationCoordinate else {
            completion(nil)
            return
        }
        
        Task {
            do {
                didSaveLocation = try await UserService.checkIfSavedLocation(uid: userId, coordinate: coord, type: .visited)
                didSaveFutureLocation = try await UserService.checkIfSavedLocation(uid: userId, coordinate: coord, type: .future)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    // MARK: - Animate to selected location
    func animateToSelectedLocation() {
        guard let coordinate = locationViewModel.selectedLocationCoordinate else { return }

        withAnimation(.easeInOut(duration: 0.6)) {
            self.cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
    }
}
