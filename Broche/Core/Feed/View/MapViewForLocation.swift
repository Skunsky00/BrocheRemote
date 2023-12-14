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
    @State private var mapSelection: MKMapItem?
//    @State private var cameraPosistion = MapCameraPosition.region(MKCoordinateRegion(
//        center: CLLocationCoordinate2D(viewModel.coordinate)
//        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//    ))


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
                    if let mapSelection = mapSelection { // Fix the variable name here
                                mapSelection.openInMaps() // Call openInMaps on the mapSelection
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
            Spacer()
        }
        .navigationTitle("Location Map")
    }
}


struct MapViewForLocation_Previews: PreviewProvider {
    static var previews: some View {
        MapViewForLocation(location: "Tennessee")
    }
}
