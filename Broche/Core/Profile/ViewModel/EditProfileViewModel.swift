//
//  EditProfileViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/22/23.
//

import PhotosUI
import Firebase
import SwiftUI
import Kingfisher

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var selectedImage: PhotosPickerItem?
    @Published var profileImage: Image?

    @Published var fullname = ""
    @Published var bio = ""
    @Published var link = ""
    @Published var linkTitle = ""
    @Published var croppedImage: UIImage?

    private var uiImage: UIImage?

    init(user: User) {
        self.user = user
        if let fullname = user.fullname { self.fullname = fullname }
        if let bio = user.bio { self.bio = bio }
        if let link = user.link { self.link = link }
        if let linkTitle = user.linkTitle { self.linkTitle = linkTitle }
    }

    func loadImage(fromItem item: PhotosPickerItem?) async {
        guard let item = item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.profileImage = Image(uiImage: uiImage)
    }

    func applyCroppedImage(_ image: UIImage) {
        self.croppedImage = image
        self.profileImage = Image(uiImage: image)
        self.uiImage = image
    }

    func updateUserData() async throws -> User {
        var data = [String: Any]()

        if let uiImage = uiImage {
            let oldImageUrl = user.profileImageUrl
            let imageUrl = try? await ImageUploader.uploadImage(image: uiImage)
            if let imageUrl {
                data["profileImageUrl"] = imageUrl
                user.profileImageUrl = imageUrl
                if let oldImageUrl, let oldURL = URL(string: oldImageUrl) {
                    KingfisherManager.shared.cache.removeImage(forKey: oldURL.absoluteString)
                }
            }
        }

        if !fullname.isEmpty && user.fullname != fullname {
            data["fullname"] = fullname
            user.fullname = fullname
        }

        if !bio.isEmpty && user.bio != bio {
            data["bio"] = bio
            user.bio = bio
        }

        if !link.isEmpty && user.link != link {
            data["link"] = link
            user.link = link
        } else if link.isEmpty && user.link != nil {
            data["link"] = FieldValue.delete()
            user.link = nil
        }

        if !linkTitle.isEmpty && user.linkTitle != linkTitle {
            data["linkTitle"] = linkTitle
            user.linkTitle = linkTitle
        } else if linkTitle.isEmpty && user.linkTitle != nil {
            data["linkTitle"] = FieldValue.delete()
            user.linkTitle = nil
        }

        if !data.isEmpty {
            try await Firestore.firestore().collection("users").document(user.id).updateData(data)
        }

        return user
    }
}

