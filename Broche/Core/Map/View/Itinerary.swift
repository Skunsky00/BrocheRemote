//
//  Itinerary.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI

struct Itinerary: View {
    var body: some View {
        VStack{
            HStack {
                Text("Itinerary comeing soon")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
    }
}

struct Itinerary_Previews: PreviewProvider {
    static var previews: some View {
        Itinerary()
    }
}
