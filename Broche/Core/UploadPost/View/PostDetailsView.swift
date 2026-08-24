//
//  PostDetailsView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/7/25.
//

import SwiftUI
import PhotosUI
import MapKit

struct PostDetailsView: View {
    @State private var caption = ""
    @State private var location = ""
    @State private var thumbnailPickerPresented = false
    @ObservedObject var viewModel: UploadPostViewModel
    @StateObject var locationSearchViewModel = UploadPostSearchViewModel()
    @State private var isShowingLocationSearch = false
    @State private var selectedLocation: MKLocalSearchCompletion?
    @State private var showAlert = false
    @State private var showErrorAlert = false
    @State private var showCancelConfirmation = false
    @Binding var tabIndex: Int
    @Binding var path: NavigationPath
    @Environment(\.colorScheme) var colorScheme
    var onFinished: () -> Void
    @Environment(\.dismiss) var dismiss
    
    // true when we already know the location (came from a visit) — locks the field
    var locationIsLocked: Bool {
        viewModel.attachedLocationId != nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Custom toolbar
            HStack {
                Button {
                    showCancelConfirmation = true
                } label: {
                    Text("Discard")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Text("New Post")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    if location.isEmpty {
                            showAlert = true
                        } else {
                            let pending = viewModel.snapshotForUpload(caption: caption, location: location)   // capture FIRST
                            UploadManager.shared.upload(pending, using: viewModel)                            // then start upload
                            clearPostDataAndReturnToFeed()                                                    // then clear — safe now, snapshot already has its own copy
                        }
                } label: {
                    Text("Upload")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .overlay(alignment: .bottom) {
                Divider()
            }
            
            // Thumbnail picker — only relevant for video posts
            if viewModel.isVideoSelected {
                VStack(alignment: .leading) {
                    Text("Thumbnail (optional)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    PhotosPicker(
                        selection: $viewModel.selectedThumbnailItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        if let thumbnailUrl = viewModel.selectedThumbnailUrl {
                            AsyncImage(url: thumbnailUrl) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 160)
                                    .aspectRatio(16/9, contentMode: .fill)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .clipped()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .shadow(radius: 2)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 160, height: 90)
                            }
                        } else if let videoUrl = viewModel.selectedVideoUrl {
                            VideoThumbnail(url: videoUrl)
                                .frame(width: 90, height: 160)
                                .aspectRatio(16/9, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(radius: 2)
                        } else {
                            Text("Tap to select a thumbnail\n(Leave blank to auto-generate)")
                                .multilineTextAlignment(.center)
                                .font(.caption)
                                .frame(width: 160, height: 90)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Input fields
            VStack(spacing: 8) {
                TextEditor(text: $caption)
                    .frame(height: 80)
                    .padding(.horizontal, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if caption.isEmpty {
                                Text("Enter your caption...")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            }
                        }
                    )
                
                Divider()
                
                if locationIsLocked {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.secondary)
                        Text(location)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                } else {
                    TextField("Enter the location", text: $location)
                        .padding(.horizontal)
                        .onTapGesture {
                            print("DEBUG: Location field tapped, navigating to locationSearch")
                            path.append("locationSearch")
                        }
                        .onChange(of: viewModel.location) { newValue in
                            location = newValue ?? ""
                        }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    print("DEBUG: Back button pressed")
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Validation Error"),
                message: Text("Please fill in the location field."),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                }
            )
        }
        .alert(isPresented: $showCancelConfirmation) {
            Alert(
                title: Text("Discard Post"),
                message: Text("Are you sure you want to discard this post?"),
                primaryButton: .destructive(Text("Discard")) {
                    clearPostDataAndReturnToFeed()
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            showErrorAlert = newValue != nil
        }
        .onAppear {
            if locationIsLocked {
                location = viewModel.location ?? ""
            }
        }
    }
    
    func clearPostDataAndReturnToFeed() {
        caption = ""
        location = ""
        viewModel.selectedItem = nil
        viewModel.selectedThumbnailItem = nil
        viewModel.selectedVideoUrl = nil
        viewModel.selectedImage = nil
        viewModel.selectedThumbnailUrl = nil
        viewModel.location = nil
        viewModel.selectedLocation = nil
        path = NavigationPath()
        tabIndex = 0
        onFinished()   // → showUpload = false
    }
}
