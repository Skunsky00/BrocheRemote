//
//  VisistedMarkerSheet.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/23.
//

import SwiftUI

struct VisitedMarkerSheet: View {
    @ObservedObject var viewModel: FutureMarkerSheetViewmodel
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @State var showEditMarker = false
    @State var showComment = false
    
    var body: some View {
        NavigationView {
            VStack {
                // header
                HStack {
                    Image(systemName: "mappin")
                        .imageScale(.large)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text(locationViewModel.selectedLocationTitle ?? "Visit")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let location = locationViewModel.selectedLocation {
                        // Render content related to the selected location
                        //                    Button {
                        //                        showComment.toggle()
                        //                    } label: {
                        //                        Image(systemName: "bubble.left")
                        //                            .imageScale(.large)
                        //                            .foregroundColor(Color(.label))
                        //                    }
                        //                    .fullScreenCover(isPresented: $showComment) {
                        //                        LocationsCommentsView(location: location)}
                        NavigationLink(
                            destination: LocationsCommentsView(location: location),
                            label: {
                                Image(systemName: "bubble.left")
                                    .imageScale(.large)
                                    .foregroundColor(Color(.label))
                            }
                        )
                    } else {
                        // Handle the case when no location is selected
                        Text("No")
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                    }
                    
                    
                    if viewModel.user.isCurrentUser {
                        Button {
                            showEditMarker.toggle()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .imageScale(.large)
                                .foregroundColor(Color(.label))
                        }.fullScreenCover(isPresented: $showEditMarker) {
                            EditVisitedMarkerSheet(user: viewModel.user, location: locationViewModel.selectedLocation!)
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
                .padding(.top, 20)
                .padding(.horizontal)
                
                Divider()
                
                // user details
                
                HStack(){
                    CircularProfileImageView(user: viewModel.user, size: .xSmall)
                    
                    Text(viewModel.user.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: 30, height: 30)
                    Text("Friends")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    
                }
                .padding(.horizontal, 10)
                
                // sheet deatils
                
                HStack {
                    if let date = locationViewModel.selectedLocation?.date {
                        Text(date)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(Color.gray)
                    } else {
                        Text("No date added yet")
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(Color.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                    
                }
                .padding(.leading)
                .padding(.top)
                
                HStack {
                    if let description = locationViewModel.selectedLocation?.description {
                        Text(description)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.leading)
                .padding(.top)
                
                // links if theey want to add any
                
                HStack {
                    if let link = locationViewModel.selectedLocation?.link {
                        Text(link)
                            .font(.footnote)
                            .overlay(
                                TextLinkView(text: (locationViewModel.selectedLocation?.link)!, linkColor: .cyan)
                            )
                    }
                }
                .padding(.top)
                
                Spacer()
            }
        }
    }
}

struct VisitedMarkerSheet_Previews: PreviewProvider {
    static var previews: some View {
        VisitedMarkerSheet(viewModel: FutureMarkerSheetViewmodel(user: User.MOCK_USERS[1]))
            .environmentObject(LocationSearchViewModel())
    }
}
