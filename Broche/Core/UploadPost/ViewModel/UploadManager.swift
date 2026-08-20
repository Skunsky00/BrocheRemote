//
//  UploadManager.swift
//  Broche
//
//  Created by Jacob Johnson on 8/19/26.
//

import Foundation
import UIKit

struct PendingUpload {
    let caption: String
    let location: String
    let isVideo: Bool
    let videoURL: URL?
    let image: UIImage?
    let attachedLocationId: String?
    let attachedVisitId: String?
}

@MainActor
final class UploadManager: ObservableObject {
    static let shared = UploadManager()

    @Published var isUploading = false
    @Published var uploadFailed = false
    @Published var lastCompletedLocationId: String? = nil

    private init() {}

    func upload(_ pending: PendingUpload, using uploader: UploadPostViewModel) {
        isUploading = true
        uploadFailed = false
        let locationId = pending.attachedLocationId

        Task {
            do {
                try await uploader.uploadPost(pending)
                self.isUploading = false
                self.lastCompletedLocationId = locationId
            } catch {
                self.isUploading = false
                self.uploadFailed = true
            }
        }
    }
}
