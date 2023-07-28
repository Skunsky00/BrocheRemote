//
//  MapViewForLocationViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 7/27/23.
//

import Foundation
import MapKit

class MapViewForLocationViewModel: ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?

    init(location: String) {
        fetchCoordinate(for: location)
    }

    private func fetchCoordinate(for location: String) {
        // Use a geocoder to get the coordinate from the location string
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            guard let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate else {
                print("Failed to fetch coordinate for location: \(location)")
                return
            }
            DispatchQueue.main.async {
                self.coordinate = coordinate
            }
        }
    }
}
