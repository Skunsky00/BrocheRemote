//
//  FutureMarkerSheet.swift
//  Broche
//
//  Created by Jacob Johnson on 8/4/23.
//

import SwiftUI

struct FutureMarkerSheet: View {
    @ObservedObject var viewModel: FutureMarkerSheetViewmodel
   
    
    var body: some View {
        
        VStack{
            // header
            HStack {
                Image(systemName: "mappin")
                    .imageScale(.large)
                    .foregroundColor(.blue)
                Spacer()
                
                Text("Itinerary")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    print("edit marker sheet")
                } label: {
                    Image(systemName: "square.and.pencil")
                        .imageScale(.large)
                        .foregroundColor(.black)
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
                    Text("Date: Aug, 13, 2023")
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                }
                .padding(.leading)
                
                HStack {
                    Text("This trip we plan to travel to anchorage alaska and then also go to homer to see otto from alask the last frontier")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.body)
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
    }
}
