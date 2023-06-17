//
//  LocationManager.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            
            // Check if the new location has a significant change in distance from the previous location
            if let previousLocation = locationManager.location,
               location.distance(from: previousLocation) < 200 { // Adjust the distance threshold as needed
                return
            }
            
            // Update the location and perform any necessary tasks
            locationManager.stopUpdatingLocation()
            // Additional code if needed
        }
    }
