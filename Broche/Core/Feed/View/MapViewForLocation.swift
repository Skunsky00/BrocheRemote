//
//  MapViewForLocation.swift
//  Broche
//
//  Created by Jacob Johnson on 7/27/23.
//

import SwiftUI
import MapKit

struct MapViewForLocation: View {
    let location: String
    @ObservedObject private var viewModel: MapViewForLocationViewModel

    init(location: String) {
        self.location = location
        self.viewModel = MapViewForLocationViewModel(location: location)
    }

    var body: some View {
        VStack {
            Text(location)
                .font(.headline)
                .padding(.top, 5)
            if let coordinate = viewModel.coordinate {
                Map(coordinateRegion: .constant(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))))
                    .frame(height: UIScreen.main.bounds.width * 1.3)
            } else {
                Text("Location coordinate not available.")
            }
            Spacer()
        }
        .navigationTitle("Location Map")
    }
}


//struct MapViewForLocation_Previews: PreviewProvider {
//    static var previews: some View {
//        MapViewForLocation()
//    }
//}
