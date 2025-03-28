//
//  SwiftUIView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/19/23.
//

import SwiftUI
import PhotosUI
import AVKit
import MapKit

// Main navigation container
struct UploadPostView: View {
    @Binding var tabIndex: Int
    @State private var path = NavigationPath()
    @StateObject var viewModel = UploadPostViewModel()
    
    var body: some View {
        NavigationStack(path: $path) {
            VideoSelectionView(path: $path, tabIndex: $tabIndex, viewModel: viewModel)
                .navigationDestination(for: String.self) { destination in
                    if destination == "postDetails" {
                        PostDetailsView(viewModel: viewModel, tabIndex: $tabIndex, path: $path)
                    } else if destination == "locationSearch" {
                        UploadPostLocationSearchView(
                            viewModel: UploadPostSearchViewModel(),
                            location: Binding(
                                get: { viewModel.location ?? "" },
                                set: { viewModel.location = $0 }
                            ),
                            isShowingLocationSearch: .constant(false),
                            selectedLocation: Binding(
                                get: { viewModel.selectedLocation },
                                set: { viewModel.selectedLocation = $0 }
                            )
                        )
                    }
                }
        }
    }
}


struct VideoSelectionView: View {
    @Binding var path: NavigationPath
    @Binding var tabIndex: Int
    @ObservedObject var viewModel: UploadPostViewModel
    @State private var imagePickerPresented = false
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isLoadingVideo {
                ProgressView("Loading Video...")
                    .padding()
            } else if let videoUrl = viewModel.selectedVideoUrl {
                VideoPlayerForUploadView(videoURL: videoUrl)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(9/16, contentMode: .fit)
                
                Button("Next") {
                    print("DEBUG: Next button pressed")
                    path.append("postDetails")
                }
                .buttonStyle(.borderedProminent)
                .padding()
            } else {
                PhotosPicker(
                    selection: $viewModel.selectedItem,
                    matching: .videos,
                    photoLibrary: .shared()
                ) {
                    Text("Select Video")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .tint(.blue)
                .accentColor(.blue)
                .environment(\.colorScheme, .light)
                .padding()
                .onTapGesture {
                    print("DEBUG: Select Video tapped, opening PhotosPicker")
                    imagePickerPresented = true
                }
                .onChange(of: viewModel.selectedItem) { _ in
                    print("DEBUG: PhotosPicker selection changed")
                    imagePickerPresented = false
                }
            }
            
            Button("Cancel") {
                print("DEBUG: Cancel button pressed")
                viewModel.selectedItem = nil
                viewModel.selectedVideoUrl = nil
                viewModel.isLoadingVideo = false
                tabIndex = 0
            }
            .foregroundColor(.red)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            print("DEBUG: VideoSelectionView appeared")
            imagePickerPresented = true // Auto-open picker
        }
        .photosPicker(isPresented: $imagePickerPresented, selection: $viewModel.selectedItem, matching: .videos)
        .tint(.blue)
        .accentColor(.blue)
        .environment(\.colorScheme, .light)
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                }
            )
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            showErrorAlert = newValue != nil
        }
    }
}
