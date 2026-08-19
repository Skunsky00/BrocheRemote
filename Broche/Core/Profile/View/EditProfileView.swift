//
//  EditProfileView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/22/23.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EditProfileViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false
    var onSave: ((User) -> Void)? = nil

    init(user: User, onSave: ((User) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: EditProfileViewModel(user: user))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // MARK: - Avatar
                    PhotosPicker(selection: $viewModel.selectedImage) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let image = viewModel.profileImage {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    CircularProfileImageView(user: viewModel.user, size: .large)
                                }
                            }
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())

                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(7)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                        }
                    }
                    .padding(.top, 12)

                    // MARK: - Fields
                    VStack(spacing: 20) {
                        EditProfileFieldView(title: "Name", placeholder: "Add your name", text: $viewModel.fullname)

                        EditProfileFieldView(title: "Bio", placeholder: "Tell people about yourself", text: $viewModel.bio, isMultiline: true)

                        VStack(alignment: .leading, spacing: 0) {
                            EditProfileFieldView(title: "Link", placeholder: "Add a link", text: $viewModel.link)

                            if !viewModel.link.isEmpty {
                                Button {
                                    viewModel.link = ""
                                } label: {
                                    Text("Remove link")
                                        .font(.footnote.weight(.medium))
                                        .foregroundColor(.red)
                                }
                                .padding(.top, 6)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Done") {
                            Task {
                                isSaving = true
                                do {
                                    let updatedUser = try await viewModel.updateUserData()
                                    onSave?(updatedUser)
                                    dismiss()
                                } catch {
                                    errorMessage = "Couldn't save your changes. Try again."
                                    showError = true
                                }
                                isSaving = false
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

private struct EditProfileFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Group {
                if isMultiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.subheadline)
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(user: User.MOCK_USERS[0])
    }
}
