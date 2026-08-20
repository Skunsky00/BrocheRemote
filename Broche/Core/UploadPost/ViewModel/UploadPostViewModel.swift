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
            Task { await loadMedia(fromItem: selectedItem) }
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
    
    @Published var selectedImage: UIImage? {
        didSet {
            print("DEBUG: selectedImage changed: \(selectedImage != nil)")
        }
    }
    
    
    @Published var selectedThumbnailUrl: URL?
    @Published var isUploading: Bool = false
    @Published var errorMessage: String?
    @Published var isLoadingVideo: Bool = false
    @Published var location: String? // Added for location search
    @Published var selectedLocation: MKLocalSearchCompletion? // Added for location search
    @Published var attachedLocationId: String? = nil
    @Published var attachedVisitId: String? = nil
    @Published var isVideoSelected: Bool = false
    
    private var videoData: Data?
    private var thumbnailImage: UIImage?
    private let db = Firestore.firestore()
    
    func loadMedia(fromItem item: PhotosPickerItem?) async {
        guard let item = item else {
            selectedVideoUrl = nil
            selectedImage = nil
            videoData = nil
            isLoadingVideo = false
            isVideoSelected = false
            print("DEBUG: No media item selected")
            return
        }

        isLoadingVideo = true

        if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            isVideoSelected = true
            selectedImage = nil
            do {
                let movie = try await item.loadTransferable(type: Movie.self)
                selectedVideoUrl = movie?.url
                print("DEBUG: Video URL loaded: \(selectedVideoUrl?.absoluteString ?? "nil")")
            } catch {
                errorMessage = "Failed to load video: \(error.localizedDescription)"
                print("DEBUG: Error loading video: \(error)")
            }
        } else {
            isVideoSelected = false
            selectedVideoUrl = nil
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    print("DEBUG: Image loaded successfully")
                } else {
                    errorMessage = "Failed to load image data"
                }
            } catch {
                errorMessage = "Failed to load image: \(error.localizedDescription)"
                print("DEBUG: Error loading image: \(error)")
            }
        }

        isLoadingVideo = false
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
    
    func snapshotForUpload(caption: String, location: String) -> PendingUpload {
        PendingUpload(
            caption: caption,
            location: location,
            isVideo: isVideoSelected,
            videoURL: selectedVideoUrl,
            image: selectedImage,
            attachedLocationId: attachedLocationId,
            attachedVisitId: attachedVisitId
        )
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
    
    func uploadPost(_ pending: PendingUpload) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let postRef = db.collection("posts").document()
        var uploadedVideoUrl: String? = nil
        var uploadedImageUrl: String? = nil
        var uploadedThumbnailUrl: String? = nil

        if pending.isVideo {
            guard let videoUrl = pending.videoURL else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video selected"])
            }
            let videoData = try Data(contentsOf: videoUrl)
            guard let result = try await VideoUploader.uploadVideo(withData: videoData) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video upload failed"])
            }
            uploadedVideoUrl = result

            if let generatedThumbnail = try await generateThumbnail(from: videoUrl) {
                uploadedThumbnailUrl = try await ThumbnailUploader.uploadThumbnail(withImage: generatedThumbnail)
            }
        } else {
            guard let image = pending.image else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No photo selected"])
            }
            guard let result = try await ImageUploader.uploadImage(image: image) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Photo upload failed"])
            }
            uploadedImageUrl = result
        }

        let post = Post(
            id: postRef.documentID,
            ownerUid: uid,
            caption: pending.caption,
            location: pending.location,
            likes: 0,
            imageUrl: uploadedImageUrl,
            videoUrl: uploadedVideoUrl,
            thumbnailUrl: uploadedThumbnailUrl,
            comments: 0,
            timestamp: Timestamp(),
            locationId: pending.attachedLocationId,
            visitId: pending.attachedVisitId
        )

        guard let encodedPost = try? Firestore.Encoder().encode(post) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode post"])
        }

        try await postRef.setData(encodedPost)
    }
}
