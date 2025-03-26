//
//  FutureMarkerSheet.swift
//  Broche
//
//  Created by Jacob Johnson on 8/4/23.
//

import SwiftUI

struct FutureMarkerSheet: View {
    @ObservedObject var viewModel: FutureMarkerSheetViewmodel
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @State var showEditMarker = false
    
    
    var body: some View {
        NavigationView {
            VStack{
                // header
                HStack {
                    Image(systemName: "mappin")
                        .imageScale(.large)
                        .foregroundColor(.blue)
                    Spacer()
                    
                    Text(locationViewModel.selectedLocationTitle ?? "Visit")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let location = locationViewModel.selectedLocation {
                        
                        NavigationLink(
                            destination: LocationsCommentsView(location: location, locationType: .future),
                            label: {
                                Image(systemName: "bubble.left")
                                    .imageScale(.large)
                                    .foregroundColor(Color(.label))
                            }
                        )
                    }
                    
                    if viewModel.user.isCurrentUser {
                        Button {
                            showEditMarker.toggle()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .imageScale(.large)
                                .foregroundColor(Color(.label))
                        }.fullScreenCover(isPresented: $showEditMarker) {
                            EditFutureMarkerView(user: viewModel.user, location: locationViewModel.selectedLocation!)
                        }
                    } else {
                        Button {
                            print("like sheet")
                        } label: {
                            Image(systemName: "heart.fill")
                                .imageScale(.large)
                                .foregroundColor(Color(.label))
                        }
                    }
                    
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Divider()
                
                ScrollView{
                    HStack(){
                        NavigationLink(destination: ProfileView(user: viewModel.user)) { // Navigate to the ProfileView
                                                    CircularProfileImageView(user: viewModel.user, size: .xSmall)
                                                }
                        
                        
                        Text(viewModel.user.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        Button {
                            print("open following locations userlist")
                        } label: {
                            Text("Nearby")
                                .font(.footnote)
                                .fontWeight(.semibold)
                            Image(systemName: "mappin.and.ellipse")
                        }
                        
                        
                        
                    }
                    .padding(.horizontal, 10)
                    
                    // date
                    HStack() {
                        if let date = locationViewModel.selectedLocation?.date {
                            Text(date)
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.gray)
                        }
                        
                        
                        
                    }
                    .padding(.leading)
                    
                    HStack {
                        if let description = locationViewModel.selectedLocation?.description {
                            Text(description)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.body)
                        }
                    }
                    .padding(.leading)
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

struct FutureMarkerSheet_Previews: PreviewProvider {
    static var previews: some View {
        FutureMarkerSheet(viewModel: FutureMarkerSheetViewmodel(user: User.MOCK_USERS[1]))
            .environmentObject(LocationSearchViewModel())
    }
}
