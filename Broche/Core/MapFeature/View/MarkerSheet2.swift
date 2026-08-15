//
//  MarkerSheet2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI
import CoreLocation // For CLLocationCoordinate2D in related components
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct MarkerSheet2: View {
    @ObservedObject var viewModel: MarkerSheetViewModel2
    @EnvironmentObject var locationViewModel: LocationSearchViewModel2
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEditMarker = false
    @State private var showUnsaveAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Beautiful card background
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header with UNSAVE BUTTON
                    HStack {
                        Button {
                            showUnsaveAlert = true
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(viewModel.type == .visited ? .red : .blue)
                                .shadow(radius: 3)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(viewModel.location.city ?? "Visit")
                            .font(.title2.bold())
                            .lineLimit(1)
                        
                        Spacer()
                        
                        NavigationLink(destination: LocationsCommentsView(location: viewModel.location, locationType: viewModel.type)) {
                            Image(systemName: "bubble.left")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                        
                        if viewModel.user.isCurrentUser {
                            Button {
                                showEditMarker.toggle()
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            }
                            .sheet(isPresented: $showEditMarker) {
                                EditMarkerView2(user: viewModel.user, location: viewModel.location, type: viewModel.type)
                            }
                        } else {
                            Button { } label: {
                                Image(systemName: "heart.fill")
                                    .font(.title3)
                                    .foregroundStyle(.pink)
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
                    
                    Divider().padding(.horizontal, 24)
                    
                    // User row
                    HStack {
                        NavigationLink(destination: ProfileView(user: viewModel.user)) {
                            CircularProfileImageView(user: viewModel.user, size: .xSmall)
                        }
                        Text(viewModel.user.username)
                            .font(.subheadline.bold())
                        Spacer()
                        Button { } label: {
                            Label("Nearby", systemImage: "mappin.and.ellipse")
                                .font(.footnote.bold())
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if let date = viewModel.location.date {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.secondary)
                            Text(date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    if let description = viewModel.location.description {
                        Text(description)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                    }
                    
                    if let link = viewModel.location.link, viewModel.type == .visited {
                        HStack {
                            TextLinkView(text: link, linkColor: .cyan)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    if viewModel.user.isCurrentUser {
                        Button {
                            if let url = URL(string: "mailto:feedback@broche.app") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Suggest Feature")
                                .font(.subheadline.bold())
                                .foregroundStyle(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        
        // Sheet presentation settings — keeps top-right button visible
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .presentationCornerRadius(28)
        
        // MARK: - UNSAVE CONFIRMATION
        .alert("Remove this pin?", isPresented: $showUnsaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    do {
                        // Convert PinType → MarkerType correctly
                        let markerType: MarkerType = viewModel.type == .visited ? .visited : .future
                        
                        try await UserService.unSaveLocation(
                            uid: viewModel.user.id,
                            location: viewModel.location,
                            type: markerType
                        )
                        
                        await MainActor.run {
                            // Reset map state
                            locationViewModel.mapViewModel?.mapState = .noInput
                            
                            // Remove from local cache
                            locationViewModel.mapViewModel?.visitedLocations.removeAll { $0.id == viewModel.location.id }
                            locationViewModel.mapViewModel?.futureLocations.removeAll { $0.id == viewModel.location.id }
                        }
                        
                        dismiss()
                    } catch {
                        await MainActor.run {
                            errorMessage = "Failed to remove pin. Try again."
                            showError = true
                        }
                    }
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}
