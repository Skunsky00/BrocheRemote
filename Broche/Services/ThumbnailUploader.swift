//
//  ThumbnailUploader.swift
//  Broche
//
//  Created by Jacob Johnson on 5/7/25.
//

import FirebaseStorage
import UIKit

struct ThumbnailUploader {
    static func uploadThumbnail(withImage image: UIImage) async throws -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("DEBUG: Failed to convert image to JPEG data")
            return nil
        }
        let filename = UUID().uuidString
        let ref = Storage.storage().reference().child("thumbnails/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            let _ = try await ref.putDataAsync(imageData, metadata: metadata)
            let url = try await ref.downloadURL()
            print("DEBUG: Thumbnail uploaded successfully to \(url)")
            return url.absoluteString
        } catch {
            print("DEBUG: Failed to upload thumbnail with error \(error.localizedDescription)")
            return nil
        }
    }
}
