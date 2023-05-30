//
//  LocationBookMarkView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import SwiftUI

struct LocationBookMarkView: View {
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
            
            HStack{
                Spacer()
                VStack{
                    Image(systemName: "mappin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    
                    Text("Visited")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Spacer()
                
                VStack{
                    Image(systemName: "airplane.departure")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    
                    Text("Future Visits")
                        .font(.system(size: 14, weight: .semibold))
                }
                Spacer()
            }
        }.padding(.bottom)
            .background(.white)
            .cornerRadius(16)
            
    }
}

struct LocationBookMarkView_Previews: PreviewProvider {
    static var previews: some View {
        LocationBookMarkView()
    }
}
