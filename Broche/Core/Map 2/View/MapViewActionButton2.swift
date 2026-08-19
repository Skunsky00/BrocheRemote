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
    let user: User
    var isInTrip: Bool = false          // NEW
    var onExitTrip: () -> Void = {}     // NEW
    var onSelectTrip: (Trip) -> Void
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
        .onboardingTarget(.createTrips)   // NEW
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isSheetPresented) {
            Itinerary(userId: user.id, user: user, canCreateTrip: true, onSelectTrip: onSelectTrip)
                .presentationDragIndicator(.visible)
        }
    }

    private func actionForState(_ state: MapViewState2) {
        switch state {
        case .noInput:
            if isInTrip {
                onExitTrip()          // CHANGED — exit instead of opening picker
            } else {
                isSheetPresented = true
            }
        case .searchingForLocation, .locationSelected:
            mapState = .noInput
        }
    }

    private func imageNameForState(_ state: MapViewState2) -> String {
        switch state {
        case .noInput:
            return isInTrip ? "arrow.left" : "line.3.horizontal"   // CHANGED
        case .searchingForLocation, .locationSelected:
            return "arrow.left"
        }
    }
}
