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
    
    @Published  var fullname = ""
    @Published  var bio = ""
    @Published  var link = ""
    @Published var croppedImage: UIImage?

    
    private var uiImage: UIImage?
    
    init(user: User) {
        self.user = user
        
        if let fullname = user.fullname {
            self.fullname = fullname
        }
        
        if let bio = user.bio {
            self.bio = bio
        }
        
        if let link = user.link {
            self.link = link
        }
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
        self.uiImage = image   // reuse existing upload path — updateUserData() already reads uiImage
    }
    
    func updateUserData() async throws -> User {
            var data = [String: Any]()

        if let uiImage = uiImage {
                let oldImageUrl = user.profileImageUrl   // NEW — capture before overwriting
                let imageUrl = try? await ImageUploader.uploadImage(image: uiImage)
                if let imageUrl {
                    data["profileImageUrl"] = imageUrl
                    user.profileImageUrl = imageUrl

                    if let oldImageUrl, let oldURL = URL(string: oldImageUrl) {   // NEW
                        KingfisherManager.shared.cache.removeImage(forKey: oldURL.absoluteString)
                    }
                }
            }

            if !fullname.isEmpty && user.fullname != fullname {
                data["fullname"] = fullname
                user.fullname = fullname   // NEW
            }

            if !bio.isEmpty && user.bio != bio {
                data["bio"] = bio
                user.bio = bio   // NEW
            }

            if !link.isEmpty && user.link != link {
                data["link"] = link
                user.link = link   // NEW
            } else if link.isEmpty && user.link != nil {
                data["link"] = FieldValue.delete()
                user.link = nil   // NEW
            }

            if !data.isEmpty {
                try await Firestore.firestore().collection("users").document(user.id).updateData(data)
            }

            return user   // NEW
        }
    }

