//
//  MapViewActionButton2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI

// Updated supporting views with "2"
struct MapViewActionButton2: View {
    @Binding var mapState: MapViewState2
    @Binding var isSheetPresented: Bool
    let userId: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button {
            withAnimation(.spring()) {
                actionForState(mapState)
            }
        } label: {
            Image(systemName: imageNameForState(mapState))
                .font(.title2)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .padding()
                .background(colorScheme == .dark ? Color.black : Color.white)
                .clipShape(Circle())
                .shadow(color: colorScheme == .dark ? .white : .black, radius: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isSheetPresented) {
                    Itinerary(userId: userId)
                        .presentationDragIndicator(.visible)
                }
    }
    
    private func actionForState(_ state: MapViewState2) {
        switch state {
        case .noInput:
            isSheetPresented = true
        case .searchingForLocation, .locationSelected:
            mapState = .noInput
        }
    }
    
    private func imageNameForState(_ state: MapViewState2) -> String {
        switch state {
        case .noInput: return "line.3.horizontal"
        case .searchingForLocation, .locationSelected: return "arrow.left"
        }
    }
}
