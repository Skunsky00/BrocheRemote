//
//  MapViewForUserPins.swift
//  Broche
//
//  Created by Jacob Johnson on 6/4/23.
//

import SwiftUI

struct MapViewForUserPins: View {
    @State private var mapState = MapViewState.noInput
    
    var body: some View {
        ZStack {
            
            
            MapViewRepresentable(mapState: $mapState)
            Rectangle()
                .frame(width: UIScreen.main.bounds.width, height: 400)
                .foregroundColor(.clear)
                .padding(.top , 100)
                
            
        }
    }
}

struct MapViewForUserPins_Previews: PreviewProvider {
    static var previews: some View {
        MapViewForUserPins()
    }
}
