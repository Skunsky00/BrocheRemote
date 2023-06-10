//
//  LocationSearchActivationView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/9/23.
//

import SwiftUI

struct LocationSearchActivationView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        HStack {
            
            Image(systemName: "mappin")
                .frame(width: 8, height: 8)
                .padding(.horizontal)
            
            Text("Search Destination.")
                .foregroundColor(colorScheme == .dark ? .white : Color(.darkGray))
            
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width - 64, height: 50)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color.black : Color.white)
                                .shadow(color: colorScheme == .dark ? .white : .black, radius: 6)
            
                
        )
    }
}

struct LocationSearchActivationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchActivationView()
    }
}
