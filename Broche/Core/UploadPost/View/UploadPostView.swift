//
//  SwiftUIView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/19/23.
//

import SwiftUI
import PhotosUI
import AVKit

struct UploadPostView: View {
    @State private var caption = ""
    @State private var location = ""
    @State private var label = ""
    @State private var imagePickerPresented = false
    @State private var selectedVideo: URL?
    @StateObject var viewModel = UploadPostViewModel()
    @Binding var tabIndex: Int
    @State private var isUploading = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            // Action toolbar
            HStack {
                Button {
                    clearPostDataAndReturnToFeed()
                } label: {
                    Text("Cancel")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                Spacer()
                
                Text("New Post")
                    .fontWeight(.semibold)
                    
                
                Spacer()
                
                Button {
                    Task {
                        do {
                            isUploading = true
                            try await viewModel.uploadPost(caption: caption, location: location, label: label)
                            clearPostDataAndReturnToFeed()
                            isUploading = false
                        } catch {
                            print("Error uploading post: \(error)")
                            // Handle the error (e.g., show an alert)
                            isUploading = false
                        }
                    }
                } label: {
                    Text("Upload")
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            
            // Post image or video
           // Group {
//                if let image = viewModel.postImage {
//                    image
            if let videoUrl = viewModel.selectedVideoUrl {
                VideoPlayerView(videoURL: videoUrl)
                      .frame(width: 200, height: 200)
              }
            
            /*else if let videoUrl = viewModel.videoUrl {
                    VideoPlayer(url: videoUrl)
                        .frame(width: 200, height: 200)
                }*/
         //   }
            
            VStack(spacing: 8) {
                Spacer()
                
                TextField("Enter your caption...", text: $caption, axis: .vertical)
                TextField("Enter the location", text: $location, axis: .vertical)
                TextField("Label", text: $label)
                Spacer()
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .onAppear {
            imagePickerPresented.toggle()
        }
        .photosPicker(isPresented: $imagePickerPresented, selection: $viewModel.selectedItem, matching: .any(of: [.videos, .not(.images)]))
        .overlay {
                    if isUploading {
                        ProgressView("Uploading...")
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
    }
    
    func clearPostDataAndReturnToFeed() {
        caption = ""
        location = ""
        label = ""
       // viewModel.selectedImage = nil
        viewModel.selectedItem = nil
//        viewModel.postImage = nil
        viewModel.selectedVideoUrl = nil
        tabIndex = 0
    }
}


struct UploadPostView_Previews: PreviewProvider {
    static var previews: some View {
        UploadPostView(tabIndex: .constant(0))
    }
}
