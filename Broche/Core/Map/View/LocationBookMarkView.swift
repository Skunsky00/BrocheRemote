//
//  LocationBookMarkView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import SwiftUI

struct LocationBookMarkView: View {
    @ObservedObject var viewModel: LocationSearchViewModel
    var coordinator: MapViewRepresentable.MapCoordinator
    var didSaveLocation: Bool { return coordinator.user.didSaveLocation ?? false }
    
    var body: some View {
        
        VStack{
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 48, height: 6)
                .padding(.top, 8)
            HStack {
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 6, height: 6)
                    .padding(.leading, -10)
                
                Spacer()
                
            Text("Searched Destination!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                    
                Spacer()
            }
            .padding()
            
            Divider()
            
            Text("SELECT MAPPIN")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding()
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack {
                
                Button {
                    if let coordinate = viewModel.selectedLocationCoordinate {
                        Task { didSaveLocation ? try await coordinator.unSave(coordinate: coordinate) : try await coordinator.save(coordinate: coordinate) }}
                } label: {
                    HStack{
                        Image(systemName: didSaveLocation ? "mappin" : "mappin.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        
                        Text("Visited")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(width: UIScreen.main.bounds.width - 32, height: 30)
                    .background(.red)
                    .cornerRadius(8)
                    .foregroundColor(.white)
                }

                
                
                HStack{
                    Image(systemName: "airplane.departure")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    
                    Text("Future Visits")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(width: UIScreen.main.bounds.width - 32, height: 30)
                .background(.blue)
                .cornerRadius(8)
                .foregroundColor(.white)
            }
            .padding(.bottom)
        }
        .background(.white)
        .cornerRadius(16)
    }
}

//struct LocationBookMarkView_Previews: PreviewProvider {
//    static var previews: some View {
//        LocationBookMarkView()
//    }
//}
