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
    @Published var activeTrip: Trip? = nil

    private var allVisitedLocations: [Location] = []
    private var allFutureLocations: [Location] = []

    private var cancellables = Set<AnyCancellable>()


    func fetchLocations(userId: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                visitedLocations = try await UserService.fetchSavedLocations(forUserID: userId, type: .visited)
                futureLocations = try await UserService.fetchSavedLocations(forUserID: userId, type: .future)
                allVisitedLocations = visitedLocations
                allFutureLocations = futureLocations
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

    func filterToTrip(_ trip: Trip) {
        let tripIds = Set(trip.locationIds)
        visitedLocations = allVisitedLocations.filter { tripIds.contains($0.id) }
        futureLocations = []
        activeTrip = trip
        fitCameraToLocations()
    }

    func exitTripView() {
        visitedLocations = allVisitedLocations
        futureLocations = allFutureLocations
        activeTrip = nil
        fitCameraToLocations()   // also good to re-fit when returning to full map
    }

    func fitCameraToLocations() {
        let allLocations = visitedLocations + futureLocations
        guard !allLocations.isEmpty else {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100)
            ))
            return
        }

        let lats = allLocations.map { $0.latitude }
        let lons = allLocations.map { $0.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 10),
            longitudeDelta: max((maxLon - minLon) * 1.4, 10)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
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
    func animateToCoordinate(_ coordinate: CLLocationCoordinate2D) {
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

extension MapViewModel {
    func addVisitedLocation(_ location: Location) {
        guard !visitedLocations.contains(where: { $0.id == location.id }) else { return }
        visitedLocations.append(location)
        allVisitedLocations.append(location)
    }
    
    func addFutureLocation(_ location: Location) {
        guard !futureLocations.contains(where: { $0.id == location.id }) else { return }
        futureLocations.append(location)
        allFutureLocations.append(location)
    }
    
    func removeVisitedLocation(id: String) {
        visitedLocations.removeAll { $0.id == id }
        allVisitedLocations.removeAll { $0.id == id }
    }
    
    func removeFutureLocation(id: String) {
        futureLocations.removeAll { $0.id == id }
        allFutureLocations.removeAll { $0.id == id }
    }
    
}
