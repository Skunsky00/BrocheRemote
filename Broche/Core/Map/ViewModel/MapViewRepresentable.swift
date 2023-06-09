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
    let locationManager = LocationManager()
    @Binding var mapState: MapViewState
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    var user: User
    
    func makeUIView(context: Context) -> some UIView {
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        print ("DEBUG: Map state is \(mapState)")
        
        switch mapState {
        case .noInput:
            context.coordinator.clearMapViewAndRecenterOnUserLocation()
            break
        case .searchingForLocation:
            break
        case .locationSelected:
            if let coordinate = locationViewModel.selectedLocationCoordinate {
                context.coordinator.addAndSelectAnnotation(withCoordinate: coordinate)
            }
            break
        }
  
    }
    
    func makeCoordinator() -> MapCoordinator {
        let coordinator = MapCoordinator(parent: self, user: user)
        coordinator.mapView = mapView // Pass the mapView reference to the coordinator
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
                
        
        // MARK: - Lifecycle
        
        init(parent: MapViewRepresentable, user: User) {
                self.parent = parent
                self.user = user
                super.init()
            }
        
        // MARK: - MKMapViewDelegate
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            
            self.currentRegion = region
            
            parent.mapView.setRegion(region, animated: true)
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
        
        func fetchSavedLocations(forUser user: User) async throws {
                    
                    
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
            self.user.didSaveLocation = await UserService.checkIfUserSavedLocation(uid: user.id, coordinate: location)
        }
        
    }
}
