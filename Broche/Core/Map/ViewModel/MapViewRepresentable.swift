//
//  MapViewRepresentable.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    
    let mapView = MKMapView()
//    @EnvironmentObject var locationManager: LocationManager
    let locationManager = LocationManager()
    @Binding var mapState: MapViewState
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    var user: User
    
    
    
    func makeUIView(context: Context) -> some UIView {
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        locationManager.requestLocation()
        
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let mapView = uiView as? MKMapView else {
            return
        }
        
        print("DEBUG: Map state is \(mapState)")

        switch mapState {
        case .noInput:
            // Update the map region when mapState is .noInput
            if let currentRegion = context.coordinator.currentRegion {
                mapView.setRegion(currentRegion, animated: true)
            } else if let userLocation = locationManager.userLocation {
                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                mapView.setRegion(region, animated: true)
            }
            Task { try await context.coordinator.fetchSaveLocations(forUser: user) }
        case .searchingForLocation:
            break
        case .locationSelected:
            if let coordinate = locationViewModel.selectedLocationCoordinate {
                context.coordinator.addAndSelectAnnotation(withCoordinate: coordinate)
                Task { try await context.coordinator.checkIfSaved(coordinate: coordinate) }
            }
            break
        }
    }
    
    func makeCoordinator() -> MapCoordinator {
        let coordinator = MapCoordinator(parent: self, user: user, locationViewModel: locationViewModel)
        coordinator.mapView = mapView // Pass the mapView reference to the coordinator
        locationViewModel.mapCoordinator = coordinator
        return coordinator
    }
}

extension MapViewRepresentable {
    
    class MapCoordinator: NSObject, MKMapViewDelegate, ObservableObject {
        
        // MARK: - Properties
        
                let parent: MapViewRepresentable
                var currentRegion: MKCoordinateRegion?
                @Published var locations: [Location] = []
                var selectedAnnotation: MKPointAnnotation?
                @Published var user: User
                weak var mapView: MKMapView?
                var locationViewModel: LocationSearchViewModel
                
        
        // MARK: - Lifecycle
        
        init(parent: MapViewRepresentable, user: User, locationViewModel: LocationSearchViewModel) {
                self.parent = parent
                self.user = user
                self.locationViewModel = locationViewModel
                super.init()
            }
        
        // MARK: - MKMapViewDelegate
        
//        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
//            let region = MKCoordinateRegion(
//                center: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude),
//                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//            )
//
//            self.currentRegion = region
//
//            parent.mapView.setRegion(region, animated: true)
//        }
        
        // MARK: - Helpers
        
        func addAndSelectAnnotation(withCoordinate coordinate: CLLocationCoordinate2D) {
            let anno = MKPointAnnotation()
            anno.coordinate = coordinate
            parent.mapView.addAnnotation(anno)
            parent.mapView.selectAnnotation(anno, animated: true)
            
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            parent.mapView.setRegion(region, animated: true)
            selectedAnnotation = anno
        }

        
        func clearMapViewAndRecenterOnUserLocation() {
           // parent.mapView.removeAnnotations(parent.mapView.annotations)
            
            if let currentRegion = currentRegion {
                parent.mapView.setRegion(currentRegion, animated: true)
            }
        }
        
        func createAnnotationsForSavedLocations() {
            guard let mapView = mapView else {
                return
            }
            
            let annotations = locations.map { location -> MKPointAnnotation in
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                return annotation
            }
            
            mapView.addAnnotations(annotations)
        }
        
        @MainActor
        func fetchSaveLocations(forUser user: User) async throws {
            do {
                self.locations = try await UserService.fetchSavedLocations(forUserID: user.id)
                createAnnotationsForSavedLocations()
            } catch {
                print("Failed to fetch saved locations with error: \(error.localizedDescription)")
            }
        }
        
        @MainActor
        func save(coordinate: CLLocationCoordinate2D) async throws {
            let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            do {
                try await UserService.saveLocation(uid: user.id, coordinate: location)
                self.user.didSaveLocation = true
                print("Location saved successfully!")
            } catch {
                print("DEBUG: Failed to save location with error: \(error.localizedDescription)")
            }
        }
        
        @MainActor
        func unSave(coordinate: CLLocationCoordinate2D) async throws {
            let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            do {
                try await UserService.unSaveLocation(uid: user.id, coordinate: location)
                self.user.didSaveLocation = false
                print("Location unsaved successfully!")
            } catch {
                print("DEBUG: Failed to unsave location with error: \(error.localizedDescription)")
            }
        }
        
        @MainActor
        func checkIfSaved(coordinate: CLLocationCoordinate2D) async throws {
            let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
            self.user.didSaveLocation = try await UserService.checkIfUserSavedLocation(uid: user.id, coordinate: location)
        }
        
    }
}
