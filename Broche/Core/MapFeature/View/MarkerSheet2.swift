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
import _PhotosUI_SwiftUI

struct MarkerSheet2: View {
    @ObservedObject var viewModel: MarkerSheetViewModel2
    @EnvironmentObject var locationViewModel: LocationSearchViewModel2
    @EnvironmentObject var markerOnboarding: MarkerOnboardingManager
    @ObservedObject private var uploadManager = UploadManager.shared   // NEW
    @Environment(\.dismiss) private var dismiss
    var onLocationUpdated: (Location) -> Void = { _ in }
    var onLocationRemoved: (Location) -> Void = { _ in }
    var autoOpenComments: Bool = false   // NEW
    
    @StateObject private var uploadViewModel = UploadPostViewModel()   // NEW
    @State private var pickerSelection: PhotosPickerItem?              // NEW
    
    @State private var showEditMarker = false
    @State private var showUnsaveAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showUpload = false            // NEW
    @State private var tabIndex = 0                  // NEW
    @State private var photoGridRefreshToken = UUID() // NEW
    @State private var showFutureActionSheet = false
    @State private var showPostDetails = false   // NEW
    @State private var showComments = false   // NEW
    
    
    var body: some View {
        ZStack {
            // Background card with blur
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // MARK: - HEADER: Pin Icon (Unsave), Title, Comments, Edit
                    HStack {
                        if viewModel.user.isCurrentUser {
                            Button {
                                if viewModel.type == .future {
                                    showFutureActionSheet = true
                                } else {
                                    showUnsaveAlert = true
                                }
                            } label: {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                                    .frame(width: 40, height: 40)
                                    .background(viewModel.type == .visited ? Color.red : Color.blue)
                                    .clipShape(Circle())
                            }
                            .markerOnboardingTarget(.unsave)
                            .buttonStyle(.plain)
                        } else {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(viewModel.type == .visited ? Color.red : Color.blue)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text(viewModel.location.city ?? "Visit")
                            .font(.title2.bold())
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            NavigationLink(destination: LocationsCommentsView(
                                location: viewModel.location,
                                locationType: viewModel.type
                            )) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Circle())
                            }
                            
                            if viewModel.user.isCurrentUser {
                                Button {
                                    showEditMarker.toggle()
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.primary)
                                        .frame(width: 36, height: 36)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Circle())
                                }
                                .markerOnboardingTarget(.edit)
                                .sheet(isPresented: $showEditMarker) {
                                    EditMarkerView2(
                                        user: viewModel.user,
                                        location: viewModel.location,
                                        type: viewModel.type,
                                        onSave: { updated in
                                            viewModel.location = updated
                                            onLocationUpdated(updated)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    
                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.top, 14)   // was 8
                        .padding(.bottom, 4) // NEW — a little breathing room before the divider
                    
                    // MARK: - User Row
                    HStack {
                        NavigationLink(destination: ProfileView(user: viewModel.user)) {
                            CircularProfileImageView(user: viewModel.user, size: .xSmall)
                        }
                        
                        Text(viewModel.user.username)
                            .font(.subheadline.bold())
                        
                        Spacer()
                        
                        if viewModel.type == .visited {
                            NavigationLink(destination: UserListView(
                                config: .friendsWhoVisited(lat: viewModel.location.latitude, lon: viewModel.location.longitude),
                                matchCoordinate: CLLocationCoordinate2D(latitude: viewModel.location.latitude, longitude: viewModel.location.longitude)
                            )) {
                                Label("Nearby", systemImage: "mappin.and.ellipse")
                                    .font(.footnote.bold())
                                    .foregroundStyle(.blue)
                            }
                            .markerOnboardingTarget(.nearby)
                        }
                        
                        if viewModel.user.isCurrentUser {
                            PhotosPicker(selection: $pickerSelection, matching: .any(of: [.images, .videos])) {
                                                            Image(systemName: "camera.fill")
                                                                .font(.subheadline)
                                                                .foregroundStyle(.white)
                                                                .padding(8)
                                                                .background(Color.blue)
                                                                .clipShape(Circle())
                                                                .overlay(
                                                                    Image(systemName: "plus.circle.fill")
                                                                        .font(.system(size: 14))
                                                                        .foregroundStyle(.white, .blue)
                                                                        .offset(x: 10, y: 10)
                                                                )
                                                        }
                                                        .markerOnboardingTarget(.addPhoto)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    
                    
                    // MARK: - Description
                    if let description = viewModel.location.description {
                        Text(description)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }
                    
                    // MARK: - Link (visited only)
                    if let link = viewModel.location.link, viewModel.type == .visited {
                        TextLinkView(text: link, linkColor: .cyan)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }

                    // MARK: - Photos
                    LocationPhotoGridPreview(location: viewModel.location, isCurrentUser: viewModel.user.isCurrentUser && viewModel.type == .visited)
                        .id(photoGridRefreshToken)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // MARK: - Albums (renamed from Visits, otherwise unchanged)
                    if viewModel.type == .visited {
                        VisitListView(location: viewModel.location, isCurrentUser: viewModel.user.isCurrentUser)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }
                    
                    Spacer(minLength: 140)
                }
                .padding(.bottom, 20)
                .frame(width: UIScreen.main.bounds.width - 32)
            }
        }
        .frame(width: UIScreen.main.bounds.width - 32)   // CHANGED — explicit
        .clipped()   // NEW — hard backstop, nothing can visually escape this boundary
        .ignoresSafeArea(edges: .bottom)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .presentationCornerRadius(28)
        .onChange(of: pickerSelection) { newItem in
            guard let newItem else { return }
            uploadViewModel.attachedLocationId = viewModel.location.id
            uploadViewModel.attachedVisitId = nil
            uploadViewModel.location = viewModel.location.city ?? ""
            uploadViewModel.selectedItem = newItem   // this alone triggers loadMedia via its own didSet
            showUpload = true                        // present immediately — VideoSelectionView shows its loading state while media loads
            pickerSelection = nil
        }
        .fullScreenCover(isPresented: $showUpload) {
            NavigationStack {
                VideoSelectionView(
                    path: .constant(NavigationPath()),
                    tabIndex: .constant(0),
                    viewModel: uploadViewModel,
                    onFinished: { showUpload = false },
                    onNext: { showPostDetails = true }
                )
                .navigationDestination(isPresented: $showPostDetails) {
                    PostDetailsView(
                        viewModel: uploadViewModel,
                        tabIndex: .constant(0),
                        path: .constant(NavigationPath()),
                        onFinished: { showUpload = false }
                    )
                }
            }
        }
        .onChange(of: uploadManager.lastCompletedLocationId) { newValue in
                    if newValue == viewModel.location.id {
                        photoGridRefreshToken = UUID()
                    }
                }
        .onAppear {
                    markerOnboarding.start()
                    if autoOpenComments {   // NEW
                        showComments = true
                        }
                       }
        .navigationDestination(isPresented: $showComments) {   // NEW
            LocationsCommentsView(location: viewModel.location, locationType: viewModel.type)
                       }
        
        // MARK: - UNSAVE CONFIRMATION ALERT
        .alert("Remove this pin?", isPresented: $showUnsaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    do {
                        let markerType: MarkerType = viewModel.type == .visited ? .visited : .future
                        
                        // In MarkerSheet2's "Remove" button action, after successfully unsaving the location:
                        try await UserService.unSaveLocation(
                            uid: viewModel.user.id,
                            location: viewModel.location,
                            type: markerType
                        )

                        // NEW — clean up any trips that reference this now-deleted pin
                        if markerType == .visited {
                            try await TripService.removeLocationFromAllTrips(
                                uid: viewModel.user.id,
                                locationId: viewModel.location.id
                            )
                        }
                        
                        await MainActor.run {
                            onLocationRemoved(viewModel.location)
                            locationViewModel.mapViewModel?.mapState = .noInput
                        }
                        dismiss()
                    } catch {
                        await MainActor.run {
                            errorMessage = "Failed to remove pin."
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
        .confirmationDialog("What would you like to do?", isPresented: $showFutureActionSheet, titleVisibility: .visible) {
            Button("Mark as Visited") {
                Task {
                    if let migrated = try? await UserService.migrateFutureToVisited(uid: viewModel.user.id, location: viewModel.location) {
                        onLocationUpdated(migrated)
                        dismiss()
                    }
                }
            }
            Button("Remove Pin", role: .destructive) {
                showUnsaveAlert = true   // reuses your existing unsave alert/logic
            }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            markerOnboarding.start()
        }
    }
}

#Preview {
    MarkerSheet2(viewModel: MarkerSheetViewModel2(
        user: .MOCK_USERS[0],
        location: Location(
            id: "123",
            ownerUid: "abc",
            latitude: 48.8566,
            longitude: 2.3522,
            city: "Paris"
        ),
        type: .visited
    ))
    .environmentObject(LocationSearchViewModel2())
}
