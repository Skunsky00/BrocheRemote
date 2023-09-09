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
                
                Image(systemName: "bubble.left.fill")
                    .imageScale(.large)
                    .foregroundColor(Color(.label))
                
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
                
                // profile and followers
                HStack(){
                    CircularProfileImageView(user: viewModel.user, size: .xSmall)
                    
                    Text(viewModel.user.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Circle()
                        .frame(width: 30, height: 30)
                    Text("Friends going")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    
                }
                .padding(.horizontal, 10)
                
                // date
                HStack() {
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

struct FutureMarkerSheet_Previews: PreviewProvider {
    static var previews: some View {
        FutureMarkerSheet(viewModel: FutureMarkerSheetViewmodel(user: User.MOCK_USERS[1]))
            .environmentObject(LocationSearchViewModel())
    }
}
