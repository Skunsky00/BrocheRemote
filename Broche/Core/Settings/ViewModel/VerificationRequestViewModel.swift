//
//  VerificationRequestViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 7/10/25.
//

// ViewModels/VerificationRequestViewModel.swift
import Firebase
import FirebaseStorage
import SwiftUI

class VerificationRequestViewModel: ObservableObject {
    @Published var selectedCategory: VerificationType = .business
    @Published var documentURL: URL?
    @Published var reason: String = ""
    @Published var isSubmitting = false
    @Published var showAlert = false
    @Published var alertMessage = ""

    func submitRequest(userId: String) {
        guard let documentURL = documentURL else {
            alertMessage = "Please upload a document"
            showAlert = true
            return
        }
        guard !reason.isEmpty else {
            alertMessage = "Please provide a reason for verification"
            showAlert = true
            return
        }

        isSubmitting = true

        // Upload document to Firebase Storage
        let storageRef = Storage.storage().reference().child("verification_documents/\(userId)/\(UUID().uuidString)")
        storageRef.putFile(from: documentURL, metadata: nil) { [weak self] metadata, error in
            guard let self = self else { return }
            guard error == nil else {
                self.alertMessage = "Failed to upload document: \(error!.localizedDescription)"
                self.showAlert = true
                self.isSubmitting = false
                return
            }

            storageRef.downloadURL { [weak self] url, error in
                guard let self = self else { return }
                guard let downloadURL = url else {
                    self.alertMessage = "Failed to get document URL"
                    self.showAlert = true
                    self.isSubmitting = false
                    return
                }

                // Save request to Firestore
                let requestData: [String: Any] = [
                    "userId": userId,
                    "category": self.selectedCategory.rawValue,
                    "documentURL": downloadURL.absoluteString,
                    "reason": self.reason,
                    "status": "pending",
                    "submittedAt": Timestamp()
                ]

                Firestore.firestore().collection("verification_requests").addDocument(data: requestData) { [weak self] error in
                    guard let self = self else { return }
                    self.isSubmitting = false
                    if let error = error {
                        self.alertMessage = "Failed to submit request: \(error.localizedDescription)"
                    } else {
                        self.alertMessage = "Request submitted successfully"
                    }
                    self.showAlert = true
                }
            }
        }
    }
}
