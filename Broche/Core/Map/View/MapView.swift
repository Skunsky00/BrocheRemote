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
    
    var user: User
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                MapViewRepresentable(mapState: $mapState, user: user)
                    .environmentObject(locationViewModel)
                    .ignoresSafeArea()
                
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
                
                MapViewActionButton(mapState: $mapState)
                    .padding(.leading)
                    .padding(.top, 4)
            }
            
            if mapState == .locationSelected {
                LocationBookMarkView(viewModel: locationViewModel, coordinator: MapViewRepresentable.MapCoordinator(parent: MapViewRepresentable(mapState: $mapState, user: user), user: user))
                    .transition(.move(edge: .bottom))
            }
        }
        //.edgesIgnoringSafeArea(.bottom)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(user: User.MOCK_USERS[0])
    }
}
