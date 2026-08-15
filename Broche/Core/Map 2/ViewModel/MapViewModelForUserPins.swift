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
    @Published var activeTrip: Trip? = nil          // NEW — nil = full map

    private var allVisitedLocations: [Location] = []
    private var allFutureLocations: [Location] = []

    func fetchLocations(userId: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                let visited = try await UserService.fetchSavedLocations(forUserID: userId, type: .visited)
                let future = try await UserService.fetchSavedLocations(forUserID: userId, type: .future)
                allVisitedLocations = visited
                allFutureLocations = future
                visitedLocations = visited
                futureLocations = future
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
        fitCameraToLocations()
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

    func animateToCoordinate(_ coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
}
