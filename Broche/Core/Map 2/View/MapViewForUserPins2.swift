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
    @State private var selectedLocationType: MarkerType = .visited
    @State private var overlayWasVisibleBeforeMarker = true   // NEW

    var user: User
    @Binding var showOverlay: Bool
    @Binding var selectedLocation: Location?
    var deepLinkLocationId: String? = nil
    var deepLinkTripId: String? = nil   // NEW param

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
                    ), onLocationUpdated: { updated in
                        if let index = viewModel.visitedLocations.firstIndex(where: { $0.id == updated.id }) {
                            viewModel.visitedLocations[index] = updated
                        }
                        if let index = viewModel.futureLocations.firstIndex(where: { $0.id == updated.id }) {
                            viewModel.futureLocations[index] = updated
                        }
                        self.selectedLocation = updated   // ← explicit `self.` reaches the @State property, not the shadowed local
                    })
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom))
                }
                .zIndex(50)
            }
            
            // MARK: - Active trip banner
            if let activeTrip = viewModel.activeTrip {
                VStack {
                    HStack(spacing: 12) {
                        Text(activeTrip.name)
                            .font(.headline)
                            .lineLimit(1)

                        Spacer()

                        Button {
                            viewModel.exitTripView()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            Task { await viewModel.toggleSaveTrip(activeTrip) }
                        } label: {
                            if viewModel.isSavingTrip {
                                ProgressView()
                                    .frame(width: 20, height: 20)
                            } else {
                                Label(viewModel.isTripSaved ? "Saved" : "Save", systemImage: viewModel.isTripSaved ? "bookmark.fill" : "bookmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(viewModel.isTripSaved ? Color.gray : Color.red)
                                    .clipShape(Capsule())
                            }
                        }
                        .disabled(viewModel.isSavingTrip)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .onAppear {
                        Task { await viewModel.checkSavedStatus(activeTrip) }
                    }

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
                            
                            if let deepLinkTripId = deepLinkTripId {   // NEW
                                            Task {
                                                if let trips = try? await TripService.fetchTrips(forUserID: user.id),
                                                   let match = trips.first(where: { $0.id == deepLinkTripId }) {
                                                    viewModel.filterToTrip(match)
                                                }
                                            }
                                        } else if let deepLinkLocationId = deepLinkLocationId {
                                if let match = viewModel.visitedLocations.first(where: { $0.id == deepLinkLocationId }) {
                                    withAnimation(.spring()) {
                                        selectedLocation = match
                                        selectedLocationType = .visited
                                    }
                                    viewModel.animateToCoordinate(.init(latitude: match.latitude, longitude: match.longitude))
                                } else if let match = viewModel.futureLocations.first(where: { $0.id == deepLinkLocationId }) {
                                    withAnimation(.spring()) {
                                        selectedLocation = match
                                        selectedLocationType = .future
                                    }
                                    viewModel.animateToCoordinate(.init(latitude: match.latitude, longitude: match.longitude))
                                }
                            }
                        }
                    }
                }
        .onChange(of: selectedLocation?.id) { newValue in
            if newValue != nil {
                // A marker is opening — remember the current preference, then force-hide
                overlayWasVisibleBeforeMarker = showOverlay
                withAnimation(.easeInOut(duration: 0.2)) {
                    showOverlay = false
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showOverlay = overlayWasVisibleBeforeMarker
                }
                withAnimation(.easeInOut(duration: 0.4)) {
                    viewModel.fitCameraToLocations()   // CHANGED back — this now correctly falls back to the US region when needed, and fits actual pins when they exist
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
                    .onboardingTarget(.viewTrips)

                    Spacer()

                    // Profile header toggle — circular person icon
                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {   // CHANGED — direct toggle, no closure
                                            showOverlay.toggle()
                                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .onboardingTarget(.hideProfile)
                }
                .padding()
                .padding(.bottom, 8)
            }
        }
    
}
