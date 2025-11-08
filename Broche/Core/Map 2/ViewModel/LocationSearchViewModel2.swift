//
//  LocationSearchViewModel2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import Foundation
import MapKit

class LocationSearchViewModel2: NSObject, ObservableObject {
    @Published var results = [MKLocalSearchCompletion]()
    @Published var selectedLocationCoordinate: CLLocationCoordinate2D?
    @Published var selectedLocationTitle: String?
    @Published var selectedLocation: Location?
    @Published var selectedUser: User?

    /// **MUST** be set from `MapView2` (e.g. in `.onAppear`)
    var userId: String = ""

    weak var mapViewModel: MapViewModel?

    private let searchCompleter = MKLocalSearchCompleter()

    @Published var queryFragment: String = "" {
        didSet { searchCompleter.queryFragment = queryFragment }
    }

    // MARK: – Init
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }

    // MARK: – Select & Resolve
    func selectLocation(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = completion.title +
            (completion.subtitle.isEmpty ? "" : ", \(completion.subtitle)")
        request.resultTypes = [.address, .pointOfInterest]

        Task {
            do {
                let response = try await MKLocalSearch(request: request).start()
                guard let item = response.mapItems.first else { return }

                // **NEW API** – `location` is **non-optional** CLLocation
                let location = item.location          // <-- no `guard let` needed
                let coordinate = location.coordinate
                let title = completion.title

                await MainActor.run {
                    self.selectedLocationCoordinate = coordinate
                    self.selectedLocationTitle = title

                    // 1. Animate map
                    self.mapViewModel?.animateToSelectedLocation()

                    // 2. Check saved status (parallel)
                    Task {
                        // ----> MARK: 1. Try / await the calls
                        async let visitedSaved = try? await UserService.checkIfSavedLocation(
                            uid: self.userId,
                            coordinate: coordinate,
                            type: .visited
                        )
                        async let futureSaved = try? await UserService.checkIfSavedLocation(
                            uid: self.userId,
                            coordinate: coordinate,
                            type: .future
                        )

                        let (isVisitedSaved, isFutureSaved) = await (
                            visitedSaved ?? false,
                            futureSaved ?? false
                        )

                        // 3. Update MapViewModel (drives the sheet UI)
                        self.mapViewModel?.didSaveLocation = isVisitedSaved
                        self.mapViewModel?.didSaveFutureLocation = isFutureSaved

                        // 4. Show the sheet
                        self.mapViewModel?.mapState = .locationSelected
                    }
                }
            } catch {
                print("Search error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension LocationSearchViewModel2: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.results = completer.results.filter { !$0.title.isEmpty }
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Completer error: \(error.localizedDescription)")
    }
}


extension LocationSearchViewModel2 {
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else { return "Remote Location" }
        
        let parts = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }
        
        if parts.isEmpty {
            if let ocean = placemark.ocean { return ocean }
            if let area = placemark.areasOfInterest?.first { return area }
            return "Remote Location"
        }
        
        return parts.joined(separator: ", ")
    }
}
