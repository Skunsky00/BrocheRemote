//
//  VerificationRequestView.swift
//  Broche
//
//  Created by Jacob Johnson on 7/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct VerificationRequestView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = VerificationRequestViewModel()
    @State private var showDocumentPicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Verification Category")) {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("Business").tag(VerificationType.business)
                        Text("Trusted Traveler").tag(VerificationType.trustedTraveler)
                    }
                }

                Section(header: Text("Document Requirements")) {
                    Text("Please upload a valid document to verify your status:\n- **Business**: Business license, tax ID, or professional certification.\n- **Trusted Traveler**: Government-issued ID, passport, or trusted traveler program card.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Section(header: Text("Reason for Verification")) {
                    TextEditor(text: $viewModel.reason)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }

                Section {
                    Button("Upload Document") {
                        showDocumentPicker = true
                    }

                    Button("Submit Request") {
                        guard let userId = AuthService.shared.currentUser?.id else {
                            print("DEBUG: No current user in VerificationRequestView")
                            viewModel.alertMessage = "Please log in to submit a verification request"
                            viewModel.showAlert = true
                            return
                        }
                        print("DEBUG: Submitting verification request for user ID: \(userId)")
                        viewModel.submitRequest(userId: userId)
                    }
                    .disabled(viewModel.isSubmitting || viewModel.documentURL == nil || viewModel.reason.isEmpty)
                }
            }
            .navigationTitle("Verification Request")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { url in
                    viewModel.documentURL = url
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Submission"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if viewModel.alertMessage.contains("success") { dismiss() }
                    }
                )
            }
            .onAppear {
                if AuthService.shared.currentUser == nil {
                    print("DEBUG: No current user on appear in VerificationRequestView")
                    viewModel.alertMessage = "User not logged in"
                    viewModel.showAlert = true
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
