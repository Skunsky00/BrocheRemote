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
            Task { try await context.coordinator.fetchFutureSavedLocations(forUser: user) }
                    
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
                @Published var futureVisitLocations: [Location] = []
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
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            // Return nil to use the default blue dot for user location
            return nil
        }

        // Check the type of the annotation and create a custom view accordingly
        if let visitedAnnotation = annotation as? VisitedLocationAnnotation {
            return createVisitedAnnotationView(for: visitedAnnotation, in: mapView)
        } else if let futureVisitAnnotation = annotation as? FutureVisitAnnotation {
            return createFutureVisitAnnotationView(for: futureVisitAnnotation, in: mapView)
        } else {
            // If it's not one of the custom annotation types, return nil for the default annotation view
            return nil
        }
    }
        
        private func createVisitedAnnotationView(for annotation: VisitedLocationAnnotation, in mapView: MKMapView) -> MKAnnotationView {
            let identifier = "VisitedAnnotationIdentifier"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            // Customize the marker color to red
            annotationView?.markerTintColor = .red
            // Remove the glyph image for visited annotations
            annotationView?.glyphImage = nil

            return annotationView!
        }

        private func createFutureVisitAnnotationView(for annotation: FutureVisitAnnotation, in mapView: MKMapView) -> MKAnnotationView {
            let identifier = "FutureVisitAnnotationIdentifier"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            // Customize the marker color to blue
            annotationView?.markerTintColor = .blue
            // Customize the marker image for future visit annotations
            annotationView?.glyphImage = UIImage(systemName: "airplane.departure")?.withTintColor(.blue)

            return annotationView!
        }
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

            mapView.removeAnnotations(mapView.annotations) // Clear existing annotations

            // Create and add annotations for visited locations
            let visitedAnnotations = locations.map { location -> VisitedLocationAnnotation in
                let annotation = VisitedLocationAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                
                return annotation
            }
            mapView.addAnnotations(visitedAnnotations)

            // Create and add annotations for future visits
            let futureVisitAnnotations = futureVisitLocations.map { location -> FutureVisitAnnotation in
                let annotation = FutureVisitAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                return annotation
            }
            mapView.addAnnotations(futureVisitAnnotations)
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
        func fetchFutureSavedLocations(forUser user: User) async throws {
                do {
                    self.futureVisitLocations = try await UserService.fetchFutureSavedLocations(forUserID: user.id)
                    createAnnotationsForSavedLocations()
                } catch {
                    print("Failed to fetch future saved locations with error: \(error.localizedDescription)")
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
        
        @MainActor
        func saveFuture(coordinate: CLLocationCoordinate2D) async throws {
                let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
                try await UserService.saveFutureLocation(uid: user.id, coordinate: location)
                self.user.didSaveFutureLocation = true
            }
            
        @MainActor
            func unsaveFuture(coordinate: CLLocationCoordinate2D) async throws {
                let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
                try await UserService.unSaveFutureLocation(uid: user.id, coordinate: location)
                self.user.didSaveFutureLocation = false
            }
            
        @MainActor
            func checkIfSavedFuture(coordinate: CLLocationCoordinate2D) async throws {
                let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
                self.user.didSaveFutureLocation = try await UserService.checkIfUserSavedFutureLocation(uid: user.id, coordinate: location)
            }
    }
}
