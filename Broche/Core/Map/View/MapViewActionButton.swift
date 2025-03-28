//
//  MapViewActionButton.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import SwiftUI

struct MapViewActionButton: View {
    @Binding var mapState: MapViewState
    @Binding var isSheetPresented: Bool // Add this binding
    let userId: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                actionForState(mapState)
            }
        }, label: {
            Image(systemName: imageNameForState(mapState))
                .font(.title2)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding()
                .background(colorScheme == .dark ? Color.black : Color.white)
                .clipShape(Circle())
                .shadow(color: colorScheme == .dark ? .white : .black, radius: 6)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isSheetPresented) { 
            Itinerary(userId: userId)
                .presentationDragIndicator(.visible)
        }
        
    }

    func actionForState(_ state: MapViewState) {
        switch state {
        case .noInput:
            isSheetPresented = true // Show the sheet when button is pressed
        case .searchingForLocation:
            mapState = .noInput
        case .locationSelected:
            mapState = .noInput
        }
    }

    func imageNameForState(_ state: MapViewState) -> String {
        switch state {
        case .noInput:
            return "line.3.horizontal"
        case .searchingForLocation, .locationSelected:
            return "arrow.left"
        }
    }
}


