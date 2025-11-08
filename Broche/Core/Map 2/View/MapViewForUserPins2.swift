//
//  MapViewForUserPins2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI
import _MapKit_SwiftUI
import Firebase
import FirebaseFirestore
import CoreLocation

struct MapViewForUserPins2: View {
    @StateObject private var viewModel = MapViewModelForUserPins()
    @StateObject private var locationManager = LocationManager2()
    @State private var showItinerary = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var user: User
    
    var body: some View {
        ZStack(alignment: .bottom) {
            mapView
            interfaceView
        }
        .onAppear {
            viewModel.updateCameraPosition(locationManager.userLocation)
            viewModel.fetchLocations(userId: user.id) { error in
                if let error {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
        .onChange(of: locationManager.userLocation) { _, newValue in
            viewModel.updateCameraPosition(newValue)
        }
        .sheet(isPresented: $showItinerary) {
            Itinerary(userId: user.id)
                .presentationDetents([.fraction(0.8), .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Location Permission Required", isPresented: Binding(
            get: { locationManager.authorizationStatus == .denied },
            set: { _ in }
        )) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable location services in Settings to view the map.")
        }
    }
    
    private var mapView: some View {
        Map(position: $viewModel.cameraPosition) {
            Group {
                ForEach(viewModel.visitedLocations, id: \.id) { loc in
                    Marker(loc.city ?? "Visited", systemImage: "mappin.circle.fill", coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
                        .tint(.red)
                }
                ForEach(viewModel.futureLocations, id: \.id) { loc in
                    Marker(loc.city ?? "Future", systemImage: "airplane.departure", coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
                        .tint(.blue)
                }
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private var interfaceView: some View {
        VStack {
            Rectangle()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.1)
                .foregroundStyle(.clear)
                .padding(.top, 100)
            
            Spacer()
            
            HStack {
                Button {
                    showItinerary = true
                } label: {
                    Text("View Itinerary")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button {
                    if let url = URL(string: "mailto:feedback@broche.app") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Suggest Feature")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}
