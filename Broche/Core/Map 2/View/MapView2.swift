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
    
    var user: User
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - MAP
                MapReader { proxy in
                    Map(position: $viewModel.cameraPosition) {
                        // Your markers...
                        UserAnnotation()
                        
                        if viewModel.mapState == .locationSelected,
                           let coord = viewModel.locationViewModel.selectedLocationCoordinate {
                            Marker(viewModel.locationViewModel.selectedLocationTitle ?? "Selected", coordinate: coord)
                                .tint(.purple)
                        }
                        
                        if viewModel.showVisitedPins {
                            ForEach(viewModel.visitedLocations) { location in
                                Marker(location.city ?? "Visited",
                                       coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                                    .tint(.red)
                            }
                        }
                        
                        if viewModel.showFuturePins {
                            ForEach(viewModel.futureLocations) { location in
                                Marker(location.city ?? "Future",
                                       coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                                    .tint(.blue)
                            }
                        }
                    }
                    .mapStyle(.standard)
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
                    .ignoresSafeArea(.all, edges: .top)
                    .simultaneousGesture(DragGesture()) // NORMAL PAN/ZOOM - SMOOTH AS APPLE MAPS
                    .gesture(
                        LongPressGesture(minimumDuration: 0.6)
                            .updating($isLongPressing) { value, state, transaction in
                                state = true
                            }
                            .onEnded { _ in
                                // DO NOTHING HERE - WE USE DragGesture FOR LOCATION
                            }
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($pressLocation) { value, state, transaction in
                                state = value.location // EXACT TOUCH LOCATION
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
                    
                    // MARK: - TOP BAR: Search Bar + Action Button (Stacked Vertically)
                    VStack(spacing: 8) {
                        // Search Activation Bar
                        if viewModel.mapState == .noInput {
                            LocationSearchActivationView2()
                                .padding(.horizontal)
                                .padding(.top, -20)  // ← Flush under notch
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        showSearchSheet = true
                                        viewModel.mapState = .searchingForLocation
                                    }
                                }
                                .zIndex(9)
                        }
                        
                        // Action Button — UNDER the search bar
                        HStack {
                            Spacer()
                            MapViewActionButton2(
                                mapState: $viewModel.mapState,
                                isSheetPresented: $isSheetPresented,
                                userId: user.id
                            )
                            .padding(.top)
                        }
                        .zIndex(10)
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
                    if viewModel.mapState == .locationSelected,
                       let coord = viewModel.locationViewModel.selectedLocationCoordinate {
                        VStack {
                            Spacer()
                            LocationBookMarkView2(
                                viewModel: viewModel.locationViewModel,
                                didSaveLocation: $viewModel.didSaveLocation,
                                didSaveFutureLocation: $viewModel.didSaveFutureLocation,
                                user: user,
                                coordinate: coord
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                            .transition(.move(edge: .bottom))
                        }
                        .zIndex(7)
                    }
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
                        withAnimation(.easeInOut(duration: 1.0)) {
                            viewModel.cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
                                    span: MKCoordinateSpan(latitudeDelta: 70, longitudeDelta: 70)
                                )
                            )
                        }
                    }
                    
                    viewModel.handleMapStateChange(newState, userId: user.id) { _ in }
                }
                .sheet(isPresented: $isSheetPresented) {
                    Text("Your Sheet Here")
                }
                
                // MARK: - FULL-SCREEN SEARCH SHEET (Same Layout)
                .fullScreenCover(isPresented: $showSearchSheet) {
                    ZStack(alignment: .top) {
                        Color(.systemBackground).ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            // MARK: - Action Button + Search Bar (Side-by-Side)
                            // Action Button (Left)
                            HStack {
                                MapViewActionButton2(
                                    mapState: $viewModel.mapState,
                                    isSheetPresented: .constant(false),
                                    userId: user.id
                                )
                                .frame(width: 44, height: 44)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            // Your FULL LocationSearchView2 (Shortened to fit)
                            LocationSearchView2(mapState: $viewModel.mapState)
                                .environmentObject(viewModel.locationViewModel)
                                .frame(maxWidth: .infinity)
                            
                                .padding(.horizontal)
                                .padding(.top)  // ← Flush under notch
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
