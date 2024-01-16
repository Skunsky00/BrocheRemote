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
    @StateObject private var viewModel = MapViewForLocationViewModel() // Create the view model as a StateObject
    @State private var mapSelection: MKMapItem?

    var body: some View {
        VStack {
            Text(location)
                .font(.headline)
                .padding(.top, 5)
            
            if let coordinate = viewModel.coordinate {
                Map {
                    Marker(location, coordinate: coordinate)
                        .tint(.blue)
                }
                .frame(height: UIScreen.main.bounds.width * 1.3)
            } else {
                Text("Location coordinate not available.")
            }
            
            HStack {
                Button {
                    if let mapSelection = mapSelection {
                        mapSelection.openInMaps()
                    }
                } label: {
                    Text("Open in Maps")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 170, height: 48)
                        .background(.blue)
                        .cornerRadius(12)
                }
            }
        }
        .onAppear {
            viewModel.fetchCoordinate(for: location) // Fetch coordinate when the view appears
        }
        .navigationTitle("Location Map")
    }
}



struct MapViewForLocation_Previews: PreviewProvider {
    static var previews: some View {
        MapViewForLocation(location: "Tennessee")
    }
}
