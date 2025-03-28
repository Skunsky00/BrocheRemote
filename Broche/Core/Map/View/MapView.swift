//
//  MapView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import SwiftUI

struct MapView: View {
    @State private var mapState = MapViewState.noInput
    @StateObject private var locationViewModel = LocationSearchViewModel()
    @State private var showFutureMarkerSheet = false
    @State private var showVisitedMarkerSheet = false
    @State private var isSheetPresented = false

    var user: User

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ZStack(alignment: .top) {
                    MapViewRepresentable(
                        mapState: $mapState,
                        user: user,
                        showFutureMarkerSheet: $showFutureMarkerSheet,
                        showVisitedMarkerSheet: $showVisitedMarkerSheet
                    )
                    .environmentObject(locationViewModel)
                    .ignoresSafeArea(.all, edges: .top)
                    
                    if mapState == .searchingForLocation {
                        LocationSearchView(mapState: $mapState)
                            .environmentObject(locationViewModel)
                    } else if mapState == .noInput {
                        LocationSearchActivationView()
                            .padding(.top, 72)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    mapState = .searchingForLocation
                                }
                            }
                    }
                    
                    MapViewActionButton(mapState: $mapState, isSheetPresented: $isSheetPresented, userId: user.id)
                        .padding(.leading)
                        .padding(.top, 4)
                }
                
                if mapState == .locationSelected {
                    if let mapCoordinator = locationViewModel.mapCoordinator {
                        LocationBookMarkView(viewModel: locationViewModel, coordinator: mapCoordinator)
                            .environmentObject(locationViewModel)
                            .transition(.move(edge: .bottom))
                    }
                }
            }
            .sheet(isPresented: $showFutureMarkerSheet) {
                FutureMarkerSheet(viewModel: FutureMarkerSheetViewmodel(user: user))
                    .environmentObject(locationViewModel)
                    .presentationDetents([.fraction(0.8), .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showVisitedMarkerSheet) {
                VisitedMarkerSheet(viewModel: FutureMarkerSheetViewmodel(user: user))
                    .environmentObject(locationViewModel)
                    .presentationDetents([.fraction(0.8), .large])
                    .presentationDragIndicator(.visible)
            }
            // Define navigation destination for User
            .navigationDestination(for: User.self) { selectedUser in
                ProfileView(user: selectedUser)
            }
            // Observe changes in selectedUser and navigate
            .onChange(of: locationViewModel.selectedUser) { selectedUser in
                if let selectedUser = selectedUser {
                    NavigationLink(destination: ProfileView(user: selectedUser)) {
                        EmptyView()
                    }.hidden()
                }
            }
        }
    }
}



struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(user: User.MOCK_USERS[0])
    }
}
