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
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                MapViewRepresentable(mapState: $mapState, user: user, showFutureMarkerSheet: $showFutureMarkerSheet, showVisitedMarkerSheet: $showVisitedMarkerSheet)
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
                
                MapViewActionButton(mapState: $mapState, isSheetPresented: $isSheetPresented)
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
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(user: User.MOCK_USERS[0])
    }
}
