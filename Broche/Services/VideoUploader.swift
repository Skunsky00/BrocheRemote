//
//  VideoUploader.swift
//  Broche
//
//  Created by Jacob Johnson on 6/1/23.
//

import Foundation
import FirebaseStorage

struct VideoUploader {
    
    static func uploadVideo(withData videoData: Data) async throws -> String? {
        let filename = NSUUID().uuidString
        let ref = Storage.storage().reference().child("/videos/\(filename)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/quicktime"
        
        do {
            let _ = try await ref.putDataAsync(videoData, metadata: metadata)
            let url = try await ref.downloadURL()
            return url.absoluteString
        } catch {
            print("DEBUG: Failed to upload video with error \(error.localizedDescription)")
            return nil
        }
    }
}
