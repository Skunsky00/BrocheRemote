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
    @StateObject var viewModel: UploadPostViewModel
    var onFinished: () -> Void = {}

    init(tabIndex: Binding<Int>, locationId: String? = nil, visitId: String? = nil, locationName: String? = nil, onFinished: @escaping () -> Void = {}) {
        self._tabIndex = tabIndex
        let vm = UploadPostViewModel()
        vm.attachedLocationId = locationId
        vm.attachedVisitId = visitId
        if let locationName = locationName {
            vm.location = locationName
        }
        self._viewModel = StateObject(wrappedValue: vm)
        self.onFinished = onFinished
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VideoSelectionView(path: $path, tabIndex: $tabIndex, viewModel: viewModel, onFinished: onFinished)
                .navigationDestination(for: String.self) { destination in
                    if destination == "postDetails" {
                        PostDetailsView(viewModel: viewModel, tabIndex: $tabIndex, path: $path, onFinished: onFinished)
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
    var onFinished: () -> Void
    var onNext: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @State private var imagePickerPresented = false
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
                    if viewModel.isLoadingVideo {
                        ProgressView("Loading...")
                            .padding()
                    } else if viewModel.isVideoSelected, let videoUrl = viewModel.selectedVideoUrl {
                        VideoPlayerForUploadView(videoURL: videoUrl)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(9/16, contentMode: .fit)
                        
                        Button("Next") {
                            if let onNext { onNext() } else { path.append("postDetails") }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    } else if !viewModel.isVideoSelected, let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(9/16, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        Button("Next") {
                            if let onNext { onNext() } else { path.append("postDetails") }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    } else {
                        ProgressView()
                    }
                }
        .navigationBarBackButtonHidden(true)
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
