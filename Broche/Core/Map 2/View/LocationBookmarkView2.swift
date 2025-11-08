//
//  LocationBookmarkView2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI
import CoreLocation

struct LocationBookMarkView2: View {
    @ObservedObject var viewModel: LocationSearchViewModel2
    @Binding var didSaveLocation: Bool
    @Binding var didSaveFutureLocation: Bool
    let user: User
    let coordinate: CLLocationCoordinate2D
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var savedStates: [PinType: Bool] = [:]
    
    var body: some View {
        VStack(spacing: 10) {
            // MARK: - Drag Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            // MARK: - Location Title
            Text(viewModel.selectedLocationTitle ?? "Unnamed Location")
                .font(.caption.bold())
                .foregroundStyle(viewModel.selectedLocationTitle == "Loading..." ? .secondary : .primary)
                .lineLimit(1)
                .padding(.horizontal)
            
            // MARK: - Pin Buttons
            HStack(spacing: 24) {
                ForEach(PinType.allCases) { type in
                    PinToggleButton(
                        type: type,
                        isSaved: savedStates[type] ?? false,
                        coordinate: coordinate,
                        title: viewModel.selectedLocationTitle ?? "",
                        userId: user.id
                    ) { newValue in
                        savedStates[type] = newValue
                        if type == .visited { didSaveLocation = newValue }
                        if type == .future { didSaveFutureLocation = newValue }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(height: 120)  // ← Bigger sheet
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
        )
        .onAppear {
            savedStates[.visited] = didSaveLocation
            savedStates[.future] = didSaveFutureLocation
        }
        .onChange(of: didSaveLocation) { savedStates[.visited] = $0 }
        .onChange(of: didSaveFutureLocation) { savedStates[.future] = $0 }
    }
}

struct PinToggleButton: View {
    let type: PinType
    let isSaved: Bool
    let coordinate: CLLocationCoordinate2D
    let title: String
    let userId: String
    let onToggle: (Bool) -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button {
            isAnimating = true
            let newSaved = !isSaved
            
            Task {
                let location = Location(
                    id: "",
                    ownerUid: userId,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    city: title.isEmpty ? nil : title
                )
                
                do {
                    if newSaved {
                        try await UserService.saveLocation(uid: userId, location: location, type: type.markerType)
                    } else {
                        try await UserService.unSaveLocation(uid: userId, location: location, type: type.markerType)
                    }
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onToggle(newSaved)
                } catch {
                    print("Save error: \(error)")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isAnimating = false
                }
            }
        } label: {
            Image(systemName: isSaved ? type.iconFilled : type.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundStyle(isSaved ? type.color : .secondary)
                .scaleEffect(isAnimating ? 1.25 : 1.0)
                .animation(.spring(response: 0.2), value: isAnimating)
        }
        .buttonStyle(.plain)
    }
}
