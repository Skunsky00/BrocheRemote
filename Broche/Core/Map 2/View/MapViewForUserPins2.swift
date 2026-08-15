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
    @State private var showItinerary = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedLocation: Location?
    @State private var selectedLocationType: MarkerType = .visited

    var user: User
    var onToggleOverlay: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            mapView
            interfaceView
            
            // MARK: - Location button, top-trailing
            VStack {
                            HStack {
                                Spacer()
                                Button {
                                    withAnimation {
                                        viewModel.cameraPosition = .userLocation(fallback: .automatic)
                                    }
                                } label: {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 16)
                                .padding(.top, 8)
                            }
                            Spacer()
                        }

            // MARK: - MARKER DETAIL SHEET
            if let selectedLocation = selectedLocation {
                VStack {
                    Spacer()
                    MarkerSheet2(viewModel: MarkerSheetViewModel2(
                        user: user,
                        location: selectedLocation,
                        type: selectedLocationType
                    ))
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom))
                }
                .zIndex(50)
            }
            
            // MARK: - Active trip banner
            if let activeTrip = viewModel.activeTrip {
                VStack {
                    HStack {
                        Text(activeTrip.name)
                            .font(.subheadline.bold())
                        Spacer()
                        Button {
                            viewModel.exitTripView()
                        } label: {
                            Label("Exit", systemImage: "xmark.circle.fill")
                                .font(.subheadline)
                        }
                    }
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.fetchLocations(userId: user.id) { error in
                if let error {
                    errorMessage = error.localizedDescription
                    showError = true
                } else {
                    viewModel.fitCameraToLocations()
                }
            }
        }
        .sheet(isPresented: $showItinerary) {
            Itinerary(userId: user.id, user: user, canCreateTrip: false) { trip in
                showItinerary = false
                viewModel.filterToTrip(trip)
            }
            .presentationDetents([.fraction(0.8), .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private var mapView: some View {
        Map(position: $viewModel.cameraPosition) {
            // VISITED PINS (Red)
            ForEach(viewModel.visitedLocations) { location in
                Annotation("", coordinate: .init(latitude: location.latitude, longitude: location.longitude)) {
                    Image(systemName: "mappin.circle")
                        .foregroundStyle(.white)
                        .font(.system(size: 24))
                        .overlay(
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 24))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedLocation = location
                                selectedLocationType = .visited
                            }
                            viewModel.animateToCoordinate(
                                .init(latitude: location.latitude, longitude: location.longitude)
                            )
                        }
                }
                .annotationTitles(.hidden)
                .annotationSubtitles(.hidden)
            }
            
            // FUTURE PINS (Blue)
            ForEach(viewModel.futureLocations) { location in
                Annotation("", coordinate: .init(latitude: location.latitude, longitude: location.longitude)) {
                    ZStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 24, height: 24)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                        Image(systemName: "airplane")
                            .foregroundStyle(.white)
                            .font(.system(size: 12))
                    }
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedLocation = location
                            selectedLocationType = .future
                        }
                        viewModel.animateToCoordinate(
                            .init(latitude: location.latitude, longitude: location.longitude)
                        )
                    }
                }
                .annotationTitles(.hidden)
                .annotationSubtitles(.hidden)
            }
        }
        .mapStyle(.standard)
           .mapControls {
               MapCompass()
               MapScaleView()
           }
           .ignoresSafeArea(.all, edges: .bottom)
           .onTapGesture {
               withAnimation(.spring()) {
                   selectedLocation = nil
               }
           }
       }

    private var interfaceView: some View {
            VStack {
                Spacer()

                HStack {
                    // Itinerary — circular hamburger icon
                    Button {
                        showItinerary = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Profile header toggle — circular person icon
                    Button {
                        onToggleOverlay?()
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .padding(.bottom, 8)
            }
        }
    
}
