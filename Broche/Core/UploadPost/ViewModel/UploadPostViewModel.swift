//
//  UploadPostViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/19/23.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import AVFoundation
import UIKit
import MapKit
import _PhotosUI_SwiftUI
import CoreTransferable

struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

@MainActor
class UploadPostViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem? {
        didSet {
            print("DEBUG: selectedItem changed: \(selectedItem != nil)")
            Task { await loadVideo(fromItem: selectedItem) }
        }
    }
    @Published var selectedThumbnailItem: PhotosPickerItem? {
        didSet {
            print("DEBUG: selectedThumbnailItem changed: \(selectedThumbnailItem != nil)")
            Task { await loadThumbnail(fromItem: selectedThumbnailItem) }
        }
    }
    @Published var selectedVideoUrl: URL? {
        didSet {
            print("DEBUG: selectedVideoUrl changed: \(selectedVideoUrl?.absoluteString ?? "nil")")
        }
    }
    @Published var selectedThumbnailUrl: URL?
    @Published var isUploading: Bool = false
    @Published var errorMessage: String?
    @Published var isLoadingVideo: Bool = false
    @Published var location: String? // Added for location search
    @Published var selectedLocation: MKLocalSearchCompletion? // Added for location search
    
    private var videoData: Data?
    private var thumbnailImage: UIImage?
    private let db = Firestore.firestore()
    
    func loadVideo(fromItem item: PhotosPickerItem?) async {
        guard let item = item else {
            selectedVideoUrl = nil
            videoData = nil
            isLoadingVideo = false
            print("DEBUG: No video item selected")
            return
        }
        do {
            isLoadingVideo = true
            print("DEBUG: Starting video load")
            let movie = try await item.loadTransferable(type: Movie.self)
            selectedVideoUrl = movie?.url
            print("DEBUG: Video URL loaded: \(selectedVideoUrl?.absoluteString ?? "nil")")
            isLoadingVideo = false
        } catch {
            isLoadingVideo = false
            errorMessage = "Failed to load video: \(error.localizedDescription)"
            print("DEBUG: Error loading video: \(error)")
        }
    }
    
    func loadThumbnail(fromItem item: PhotosPickerItem?) async {
        guard let item = item else {
            selectedThumbnailUrl = nil
            thumbnailImage = nil
            print("DEBUG: No thumbnail item selected")
            return
        }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                thumbnailImage = image
                selectedThumbnailUrl = try saveThumbnailLocally(data: data)
                print("DEBUG: Thumbnail loaded successfully: \(selectedThumbnailUrl?.absoluteString ?? "nil")")
            } else {
                errorMessage = "Failed to load thumbnail data"
                print("DEBUG: No data loaded for thumbnail")
            }
        } catch {
            errorMessage = "Failed to load thumbnail: \(error.localizedDescription)"
            print("DEBUG: Error loading thumbnail data: \(error)")
        }
    }
    
    func saveThumbnailLocally(data: Data) throws -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let temporaryFile = temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        try data.write(to: temporaryFile)
        return temporaryFile
    }
    
    func generateThumbnail(from videoURL: URL) async throws -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            print("DEBUG: Generated thumbnail for video: \(videoURL)")
            return image
        } catch {
            print("DEBUG: Error generating thumbnail: \(error)")
            return nil
        }
    }
    
    func uploadPost(caption: String, location: String, label: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        isUploading = true
        errorMessage = nil
        let postRef = db.collection("posts").document()
        
        guard let videoUrl = selectedVideoUrl else {
            isUploading = false
            errorMessage = "No video selected"
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video selected"])
        }
        
        do {
            videoData = try Data(contentsOf: videoUrl)
        } catch {
            isUploading = false
            errorMessage = "Failed to load video data for upload"
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load video data"])
        }
        
        guard let uploadedVideoUrl = try await VideoUploader.uploadVideo(withData: videoData!) else {
            isUploading = false
            errorMessage = "Video upload failed"
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video upload failed"])
        }
        
        var uploadedThumbnailUrl: String?
        if let thumbnailImage = thumbnailImage {
            uploadedThumbnailUrl = try await ThumbnailUploader.uploadThumbnail(withImage: thumbnailImage)
        } else if let generatedThumbnail = try await generateThumbnail(from: videoUrl) {
            uploadedThumbnailUrl = try await ThumbnailUploader.uploadThumbnail(withImage: generatedThumbnail)
        }
        
        let post = Post(
            id: postRef.documentID,
            ownerUid: uid,
            caption: caption,
            location: location,
            likes: 0,
            imageUrl: nil,
            videoUrl: uploadedVideoUrl,
            thumbnailUrl: uploadedThumbnailUrl,
            label: label,
            comments: 0,
            timestamp: Timestamp()
        )
        
        guard let encodedPost = try? Firestore.Encoder().encode(post) else {
            isUploading = false
            errorMessage = "Failed to encode post"
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode post"])
        }
        
        try await postRef.setData(encodedPost)
        print("DEBUG: Finished post upload")
        isUploading = false
    }
}
