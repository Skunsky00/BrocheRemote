//
//  MapView2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI
import _MapKit_SwiftUI
import Combine
import Firebase
import FirebaseFirestore
import CoreLocation

struct MapView2: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager2()
    @GestureState private var pressLocation: CGPoint = .zero
    @GestureState private var isLongPressing = false

    @State private var isSheetPresented = false
    @State private var showSearchSheet = false
    @State private var selectedLocation: Location?
    @State private var selectedLocationType: MarkerType = .visited
    @State private var showTripSelector = false
    @State private var showEditTrip = false
    @State private var lastSelectedCoordinate: CLLocationCoordinate2D?   // NEW

    var user: User

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - MAP
                MapReader { proxy in
                    Map(position: $viewModel.cameraPosition) {
                        UserAnnotation()

                        if viewModel.mapState == .locationSelected,
                           let coord = viewModel.locationViewModel.selectedLocationCoordinate {
                            Marker(viewModel.locationViewModel.selectedLocationTitle ?? "Selected", coordinate: coord)
                                .tint(.purple)
                        }

                        if viewModel.showVisitedPins {
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
                                                viewModel.mapState = .locationSelected
                                            }
                                            lastSelectedCoordinate = .init(latitude: location.latitude, longitude: location.longitude)   // NEW
                                            viewModel.animateToCoordinate(.init(latitude: location.latitude, longitude: location.longitude))
                                        }
                                }
                                .annotationTitles(.hidden)
                                .annotationSubtitles(.hidden)
                            }
                        }

                        if viewModel.showFuturePins {
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
                                            viewModel.mapState = .locationSelected
                                        }
                                        lastSelectedCoordinate = .init(latitude: location.latitude, longitude: location.longitude)   // NEW
                                        viewModel.animateToCoordinate(.init(latitude: location.latitude, longitude: location.longitude))
                                    }
                                }
                                .annotationTitles(.hidden)
                                .annotationSubtitles(.hidden)
                            }
                        }
                    }
                    .mapStyle(.standard)
                    .mapControls {
                        MapScaleView()
                    }
                    .ignoresSafeArea(.all, edges: .top)
                    .simultaneousGesture(DragGesture())
                    .gesture(
                        LongPressGesture(minimumDuration: 0.6)
                            .updating($isLongPressing) { value, state, transaction in
                                state = true
                            }
                            .onEnded { _ in }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($pressLocation) { value, state, transaction in
                                state = value.location
                            }
                            .onEnded { value in
                                if isLongPressing {
                                    guard let coordinate = proxy.convert(pressLocation, from: .local) else { return }

                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                                    viewModel.locationViewModel.selectedLocationCoordinate = coordinate
                                    viewModel.locationViewModel.selectedLocationTitle = "Loading..."
                                    viewModel.animateToSelectedLocation()
                                    viewModel.mapState = .locationSelected

                                    Task {
                                        do {
                                            let address = try await viewModel.locationViewModel.reverseGeocode(coordinate)
                                            await MainActor.run {
                                                viewModel.locationViewModel.selectedLocationTitle = address.isEmpty ? "Remote Location" : address
                                            }
                                        } catch {
                                            await MainActor.run {
                                                viewModel.locationViewModel.selectedLocationTitle = "Remote Location"
                                            }
                                        }

                                        async let visited = try? await UserService.checkIfSavedLocation(uid: user.id, coordinate: coordinate, type: .visited)
                                        async let future = try? await UserService.checkIfSavedLocation(uid: user.id, coordinate: coordinate, type: .future)
                                        let (v, f) = await (visited ?? false, future ?? false)

                                        await MainActor.run {
                                            viewModel.didSaveLocation = v
                                            viewModel.didSaveFutureLocation = f
                                        }
                                    }
                                }
                            }
                    )
                }

                // MARK: - TOP BAR: Search Bar / Trip Banner + Action Button
                VStack(spacing: 8) {
                    // Only show search bar OR trip banner when idle — never both, never neither
                    if viewModel.mapState == .noInput {
                        if let activeTrip = viewModel.activeTrip {
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
                                    showEditTrip = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            .padding(.top, -20)
                        } else {
                            LocationSearchActivationView2()
                                .padding(.horizontal)
                                .padding(.top, -20)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        showSearchSheet = true
                                        viewModel.mapState = .searchingForLocation
                                    }
                                }
                                .zIndex(9)
                        }
                    }

                    // Action button — ALWAYS renders, regardless of trip state,
                    // so it can always act as the back arrow to close a marker sheet
                    HStack {
                        Spacer()
                        MapViewActionButton2(
                            mapState: $viewModel.mapState,
                            isSheetPresented: $isSheetPresented,
                            user: user,
                            isInTrip: viewModel.activeTrip != nil,
                            onExitTrip: { viewModel.exitTripView() },
                            onSelectTrip: { trip in
                                isSheetPresented = false
                                viewModel.filterToTrip(trip)
                            }
                        )
                        .offset(y: viewModel.mapState == .locationSelected ? -120 : 0)
                        .animation(.spring())
                        .padding(.top, viewModel.mapState == .locationSelected ? 60 : 0)
                        .zIndex(999)
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .top)

                // MARK: - LOCATION BUTTON (Bottom-Right)
                if viewModel.mapState == .noInput {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                locationManager.requestLocation()
                                if let location = locationManager.userLocation {
                                    withAnimation(.easeInOut) {
                                        viewModel.cameraPosition = .region(
                                            MKCoordinateRegion(
                                                center: location.coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            )
                                        )
                                    }
                                }
                            } label: {
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 30)
                        }
                    }
                    .zIndex(8)
                    .transition(.opacity)
                }

                // MARK: - BOOKMARK SHEET
                if viewModel.mapState == .locationSelected {
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
                                viewModel.removeFutureLocation(id: updated.id)
                                if !viewModel.visitedLocations.contains(where: { $0.id == updated.id }) {
                                    viewModel.addVisitedLocation(updated)
                                }
                                self.selectedLocation = updated
                                self.selectedLocationType = .visited
                            }, onLocationRemoved: { removed in
                                viewModel.removeVisitedLocation(id: removed.id)
                                viewModel.removeFutureLocation(id: removed.id)
                                self.selectedLocation = nil
                                viewModel.mapState = .noInput
                            })
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                            .transition(.move(edge: .bottom))
                        }
                        .zIndex(50)
                    } else if viewModel.locationViewModel.selectedLocationCoordinate != nil {
                        VStack {
                            Spacer()
                            LocationBookMarkView2(
                                viewModel: viewModel.locationViewModel,
                                didSaveLocation: $viewModel.didSaveLocation,
                                didSaveFutureLocation: $viewModel.didSaveFutureLocation,
                                user: user,
                                coordinate: viewModel.locationViewModel.selectedLocationCoordinate!
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                            .transition(.move(edge: .bottom))
                        }
                        .zIndex(7)
                    }
                }
                // REMOVED — duplicate trip banner that was here is gone;
                // trip banner now lives only in the top-bar block above
            }
            .onAppear {
                viewModel.fetchLocations(userId: user.id) { _ in }
                viewModel.locationViewModel.mapViewModel = viewModel
                viewModel.locationViewModel.userId = user.id
            }
            .onChange(of: viewModel.mapState) { _, newState in
                           if newState != .searchingForLocation {
                               showSearchSheet = false
                           }

                           if newState == .noInput {
                               selectedLocation = nil
                               viewModel.locationViewModel.selectedLocationCoordinate = nil
                               viewModel.locationViewModel.selectedLocationTitle = nil
                               withAnimation(.easeInOut(duration: 0.4)) {   // CHANGED — was 1.0
                                   if let coordinate = lastSelectedCoordinate {   // NEW
                                       viewModel.cameraPosition = .region(MKCoordinateRegion(
                                           center: coordinate,
                                           span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 25)
                                       ))
                                   } else {
                                       viewModel.cameraPosition = .region(
                                           MKCoordinateRegion(
                                               center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                                               span: MKCoordinateSpan(latitudeDelta: 70, longitudeDelta: 70)
                                           )
                                       )
                                   }
                               }
                           }

                           viewModel.handleMapStateChange(newState, userId: user.id) { _ in }
                       }
            .sheet(isPresented: $isSheetPresented) {
                Text("Your Sheet Here")
            }
            .sheet(isPresented: $showTripSelector) {
                TripPinSelectorView(user: user)
            }
            .sheet(isPresented: $showEditTrip) {
                if let activeTrip = viewModel.activeTrip {
                    TripPinSelectorView(user: user, existingTrip: activeTrip)
                }
            }
            .onChange(of: showEditTrip) {
                // Refresh the active trip's data after editing closes
                if !showEditTrip, let updatedId = viewModel.activeTrip?.id {
                    Task {
                        if let refreshed = try? await TripService.fetchTrips(forUserID: user.id).first(where: { $0.id == updatedId }) {
                            viewModel.filterToTrip(refreshed)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showSearchSheet) {
                ZStack(alignment: .top) {
                    Color(.systemBackground).ignoresSafeArea()

                    VStack(spacing: 12) {
                        HStack {
                            MapViewActionButton2(
                                mapState: $viewModel.mapState,
                                isSheetPresented: $isSheetPresented,
                                user: user,
                                isInTrip: viewModel.activeTrip != nil,
                                onExitTrip: { viewModel.exitTripView() },
                                onSelectTrip: { trip in
                                    isSheetPresented = false
                                    viewModel.filterToTrip(trip)
                                }
                            )
                            .frame(width: 44, height: 44)
                            Spacer()
                        }
                        .padding(.horizontal)

                        LocationSearchView2(mapState: $viewModel.mapState, selectedExistingLocation: $selectedLocation)
                            .environmentObject(viewModel.locationViewModel)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}




#Preview("MapView2 - Dark Mode") {
    MapView2(user: User.MOCK_USERS[0])
        .environmentObject(LocationSearchViewModel2())
        .preferredColorScheme(.dark)
}
