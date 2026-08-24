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
    @State private var savedLocationIds: [PinType: Location] = [:]
    
    private var hasSelection: Bool {   // NEW
        (savedStates[.visited] ?? false) || (savedStates[.future] ?? false)
    }
    
    var body: some View {
        VStack(spacing: 14) {
            Capsule()   // NEW — capsule now on its own, tight to the top edge
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
            
            HStack {   // NEW — Done button gets its own row, no longer sharing space with the capsule
                Spacer()
                Button {
                    withAnimation(.spring()) {
                        viewModel.mapViewModel?.mapState = .noInput
                    }
                } label: {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(hasSelection ? .white : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(hasSelection ? Color.blue : Color(.systemGray5))
                        .clipShape(Capsule())
                }
                .disabled(!hasSelection)
                .animation(.easeInOut(duration: 0.2), value: hasSelection)
            }
            .padding(.trailing, 16)
            
            Text(viewModel.selectedLocationTitle ?? "Unnamed Location")
                .font(.headline)
                .foregroundStyle(viewModel.selectedLocationTitle == "Loading..." ? .secondary : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                ForEach(PinType.allCases) { type in
                    let isSaved = savedStates[type] ?? false
                    PinToggleButton(
                        type: type,
                        isSaved: isSaved,
                        coordinate: coordinate,
                        title: viewModel.selectedLocationTitle ?? "",
                        userId: user.id
                    ) { newValue, savedLocation in
                        savedStates[type] = newValue
                        
                        if newValue, let savedLocation {
                            savedLocationIds[type] = savedLocation
                        }
                        
                        if type == .visited {
                            didSaveLocation = newValue
                            if newValue, let savedLocation {
                                viewModel.mapViewModel?.addVisitedLocation(savedLocation)
                            } else if !newValue, let toRemove = savedLocationIds[type] {
                                viewModel.mapViewModel?.removeVisitedLocation(id: toRemove.id)
                                savedLocationIds[type] = nil
                            }
                        }
                        if type == .future {
                            didSaveFutureLocation = newValue
                            if newValue, let savedLocation {
                                viewModel.mapViewModel?.addFutureLocation(savedLocation)
                            } else if !newValue, let toRemove = savedLocationIds[type] {
                                viewModel.mapViewModel?.removeFutureLocation(id: toRemove.id)
                                savedLocationIds[type] = nil
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
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
    let onToggle: (Bool, Location?) -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button {
            isAnimating = true
            let newSaved = !isSaved
            Task {
                let location = Location(id: "", ownerUid: userId, latitude: coordinate.latitude, longitude: coordinate.longitude, city: title.isEmpty ? nil : title)
                do {
                    if newSaved {
                        if type == .future {
                            let alreadyVisited = (try? await UserService.checkIfSavedLocation(uid: userId, coordinate: coordinate, type: .visited)) ?? false
                            if alreadyVisited {
                                isAnimating = false
                                return
                            }
                        }
                        if type == .visited {   // NEW — block saving as Visited if already Future here
                            let alreadyFuture = (try? await UserService.checkIfSavedLocation(uid: userId, coordinate: coordinate, type: .future)) ?? false
                            if alreadyFuture {
                                isAnimating = false
                                return   // silently block — it's already planned as a future visit, don't also mark it visited
                            }
                        }
                        let saved = try await UserService.saveLocation(uid: userId, location: location, type: type.markerType)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onToggle(newSaved, saved)
                    } else {
                        try await UserService.unSaveLocation(uid: userId, location: location, type: type.markerType)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onToggle(newSaved, nil)
                    }
                } catch { print("Save error: \(error)") }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isAnimating = false }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: isSaved ? type.iconFilled : type.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSaved ? .white : type.color)
                Text(type.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSaved ? .white : type.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSaved ? type.color : type.color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(isAnimating ? 1.08 : 1.0)
            .animation(.spring(response: 0.2), value: isAnimating)
        }
        .buttonStyle(.plain)
    }
}
