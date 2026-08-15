//
//  TripPinSelectorViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 8/10/26.
//

import Foundation
import _MapKit_SwiftUI
import CoreLocation

@MainActor
class TripPinSelectorViewModel: ObservableObject {
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var visitedLocations: [Location] = []
    @Published var selectedLocationIds: Set<String> = []
    @Published var isSaving = false
    @Published var errorMessage: String?

    let existingTrip: Trip?   // nil = creating new, non-nil = editing

    init(existingTrip: Trip? = nil) {
        self.existingTrip = existingTrip
        if let existingTrip {
            self.selectedLocationIds = Set(existingTrip.locationIds)
        }
    }

    func fetchLocations(userId: String) {
        Task {
            do {
                visitedLocations = try await UserService.fetchSavedLocations(forUserID: userId, type: .visited)
                print("DEBUG: TripPinSelector fetched \(visitedLocations.count) locations")
                fitCameraToLocations()
            } catch {
                errorMessage = error.localizedDescription
                print("DEBUG: TripPinSelector fetch error: \(error.localizedDescription)")
            }
        }
    }

    func toggleSelection(for location: Location) {
        if selectedLocationIds.contains(location.id) {
            selectedLocationIds.remove(location.id)
        } else {
            selectedLocationIds.insert(location.id)
        }
    }

    func isSelected(_ location: Location) -> Bool {
        selectedLocationIds.contains(location.id)
    }

    func fitCameraToLocations() {
        guard !visitedLocations.isEmpty else { return }
        let lats = visitedLocations.map { $0.latitude }
        let lons = visitedLocations.map { $0.longitude }
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

    func saveTrip(userId: String, name: String) async -> Bool {
        print("DEBUG: saveTrip called with name: \(name), selected: \(selectedLocationIds)")
        guard !selectedLocationIds.isEmpty else {
            errorMessage = "Select at least one pin for the trip."
            return false
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Give your trip a name."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            if let existingTrip {
                var updated = existingTrip
                updated.name = name
                updated.locationIds = Array(selectedLocationIds)
                try await TripService.updateTrip(uid: userId, trip: updated)
                print("DEBUG: saveTrip - updated existing trip \(updated.id)")
            } else {
                let newTrip = try await TripService.createTrip(
                    uid: userId,
                    name: name,
                    locationIds: Array(selectedLocationIds)
                )
                print("DEBUG: saveTrip - created new trip \(newTrip.id)")
            }
            return true
        } catch {
            print("DEBUG: saveTrip FAILED with error: \(error)")
            errorMessage = error.localizedDescription
            return false
        }
    }
}
