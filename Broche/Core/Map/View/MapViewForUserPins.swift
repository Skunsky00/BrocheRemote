//
//  MapViewForUserPins.swift
//  Broche
//
//  Created by Jacob Johnson on 6/4/23.
//

import SwiftUI

struct MapViewForUserPins: View {
    @State private var mapState = MapViewState.noInput
    @StateObject private var locationViewModel = LocationSearchViewModel()
    var user: User
    
    var body: some View {
        ZStack {
            
            
            MapViewRepresentable(mapState: $mapState, user: user)
                .environmentObject(locationViewModel)
            Rectangle()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 1.1)
                .foregroundColor(.clear)
                .padding(.top , 100)
                
            
        }
    }
}

struct MapViewForUserPins_Previews: PreviewProvider {
    static var previews: some View {
        MapViewForUserPins(user: User.MOCK_USERS[0])
    }
}
