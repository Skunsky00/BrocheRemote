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
    var onChangeSelection: (() -> Void)? = nil

    @StateObject private var player = LoopingPlayerViewModel()
    @StateObject private var editor = MediaEditorViewModel()
    @State private var imagePickerPresented = false
    @State private var showErrorAlert = false

    var body: some View {
        GeometryReader { geo in
            let canvasSize = CGSize(width: geo.size.width,
                                    height: geo.size.width / editor.aspect.ratio)
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.isLoadingVideo {
                    ProgressView().tint(.white)
                } else if viewModel.isVideoSelected, let url = viewModel.selectedVideoUrl {
                    videoPreview(url: url, geo: geo)
                } else if let image = editor.source {
                    photoPreview(image: image, canvasSize: canvasSize, geo: geo)
                } else {
                    emptyState
                }

                VStack {
                    topBar
                    Spacer()
                    bottomBar
                }
                .padding(.horizontal, 16)
            }
        }
        .overlay {
            if editor.isEditingText {
                TextEditingView(editor: editor)
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .photosPicker(isPresented: $imagePickerPresented,
                      selection: $viewModel.selectedItem,
                      matching: .any(of: [.images, .videos]))
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                  dismissButton: .default(Text("OK")) { viewModel.errorMessage = nil })
        }
        .onChange(of: viewModel.errorMessage) { showErrorAlert = $0 != nil }
        .onChange(of: viewModel.selectedImage) { newImage in
            // ignore the image we baked ourselves; only react to a new pick
            if let newImage, newImage !== editor.lastBaked { editor.setSource(newImage) }
        }
        .onChange(of: viewModel.selectedVideoUrl) { url in
            if let url { player.load(url: url) }
        }
        .onAppear {
            if let img = viewModel.selectedImage, editor.source == nil { editor.setSource(img) }
            if let url = viewModel.selectedVideoUrl { player.load(url: url) }
            if viewModel.isVideoSelected { player.play() }
        }
        .onDisappear { player.pause() }
        .tint(.white)
    }

    // MARK: - Previews

    private func videoPreview(url: URL, geo: GeometryProxy) -> some View {
        PlayerLayerView(player: player.player)
            .frame(width: geo.size.width, height: geo.size.width / MediaEditorViewModel.Aspect.story.ratio)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { player.togglePlay() }
            .overlay {
                if !player.isPlaying {
                    Image(systemName: "play.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.85))
                        .allowsHitTesting(false)
                }
            }
    }

    private func photoPreview(image: UIImage, canvasSize: CGSize, geo: GeometryProxy) -> some View {
        PhotoCanvasView(editor: editor, image: image, size: canvasSize)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No media selected").foregroundStyle(.white.opacity(0.7))
            Button("Choose another") { changeSelection() }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            circleButton("chevron.left") { changeSelection() }
            Spacer()
            if viewModel.isVideoSelected {
                circleButton(player.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                    player.toggleMute()
                }
            } else if editor.source != nil {
                circleButton("textformat") { editor.beginNewText() }
            }
        }
        .padding(.top, 8)
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            if !viewModel.isVideoSelected, editor.source != nil {
                HStack(spacing: 8) {
                    ForEach(MediaEditorViewModel.Aspect.allCases, id: \.self) { aspect in
                        Button(aspect.label) { editor.aspect = aspect }
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(editor.aspect == aspect ? Color.white : Color.white.opacity(0.2))
                            .foregroundStyle(editor.aspect == aspect ? .black : .white)
                            .clipShape(Capsule())
                    }
                    Button("Reset") { editor.resetTransform() }
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.leading, 8)
                }
            }

            if viewModel.isVideoSelected || editor.source != nil {
                Button(action: next) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.bottom, 12)
    }

    private func circleButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.45))
                .clipShape(Circle())
        }
    }

    // MARK: - Actions

    private func changeSelection() {
        player.pause()
        if let onChangeSelection { onChangeSelection() } else { imagePickerPresented = true }
    }

    private func next() {
        if !viewModel.isVideoSelected, editor.source != nil {
            let width = UIScreen.main.bounds.width
            let size = CGSize(width: width, height: width / editor.aspect.ratio)
            if let baked = editor.render(canvasSize: size) {
                viewModel.selectedImage = baked
            }
        }
        if let onNext { onNext() } else { path.append("postDetails") }
    }
}
