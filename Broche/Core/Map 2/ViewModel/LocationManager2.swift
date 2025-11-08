//
//  LocationManager2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//


import Foundation
import CoreLocation

@MainActor
class LocationManager2: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var locationContinuation: AsyncStream<CLLocation>.Continuation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocation()
    }
    
    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            // Handle restricted or denied states
            authorizationStatus = manager.authorizationStatus
        }
        
        // Set up AsyncStream for location updates
        Task {
            for await location in makeLocationStream() {
                self.userLocation = location
            }
        }
    }
    
    private func makeLocationStream() -> AsyncStream<CLLocation> {
        AsyncStream { continuation in
            self.locationContinuation = continuation
            continuation.onTermination = { @Sendable _ in
                self.manager.stopUpdatingLocation()
            }
        }
    }
}

extension LocationManager2: @MainActor CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationContinuation?.yield(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        } else if status == .denied || status == .restricted {
            userLocation = nil
            locationContinuation?.finish()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        locationContinuation?.finish()
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

