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
                        
                        NavigationLink(
                            destination: LocationsCommentsView(location: location, locationType: .visited),
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
                
                // sheet deatils
                
                HStack {
                    if let date = locationViewModel.selectedLocation?.date {
                        Text(date)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(Color.gray)
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
                        ZStack(alignment: .bottomLeading) {
                            Text(link)
                                .font(.footnote)
                                .foregroundColor(.cyan)
                            
                            TextLinkView(text: link, linkColor: .cyan)
                        }
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
