//
//  SharePostViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 7/9/25.
//

import Firebase
import FirebaseAuth
import Foundation

@MainActor
class SharePostViewModel: ObservableObject {
    @Published var followingUsers = [User]()
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchFollowingUsers() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user.")
            errorMessage = "No authenticated user."
            return
        }

        isLoading = true
        followingUsers.removeAll()
        print("🔍 Starting fetch for following users for uid: \(uid)")

        Task {
            do {
                let snapshot = try await COLLECTION_FOLLOWING
                    .document(uid)
                    .collection("user-following")
                    .getDocuments()

                print("📄 Found \(snapshot.documents.count) following documents.")

                var fetchedUsers = [User]()
                for doc in snapshot.documents {
                    print("➡️ Fetching user for uid: \(doc.documentID)")
                    do {
                        let user = try await UserService.fetchUser(withUid: doc.documentID)
                        if user.id.isEmpty {
                            print("⚠️ User with empty ID: \(doc.documentID)")
                            continue
                        }
                        fetchedUsers.append(user)
                        print("✅ Added user: \(user.username), id: \(user.id)")
                    } catch {
                        print("❌ Failed to fetch user \(doc.documentID): \(error.localizedDescription)")
                    }
                }

                print("✅ Fetched \(fetchedUsers.count) users: \(fetchedUsers.map { $0.username })")
                self.followingUsers = fetchedUsers
                self.errorMessage = fetchedUsers.isEmpty ? "No users found." : nil
                print("✅ Assigned \(self.followingUsers.count) users to followingUsers")
            } catch {
                print("❌ Failed to fetch following users: \(error.localizedDescription)")
                self.errorMessage = "Failed to fetch users: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }

    func sendPost(to user: User, post: Post) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            errorMessage = "No authenticated user."
            return
        }

        let messageId = UUID().uuidString
        let timestamp = Timestamp(date: Date())

        // Data for the sender (isRead: true)
        let senderData: [String: Any] = [
            "id": messageId,
            "fromId": currentUid,
            "toId": user.id,
            "text": "",
            "timestamp": timestamp,
            "postId": post.id ?? "",
            "postImageUrl": post.imageUrl ?? "",
            "videoUrl": post.videoUrl ?? "",
            "thumbnailUrl": post.thumbnailUrl ?? "",
            "isRead": true // Sender has read their own message
        ]

        // Data for the receiver (isRead: false)
        let receiverData: [String: Any] = [
            "id": messageId,
            "fromId": currentUid,
            "toId": user.id,
            "text": "",
            "timestamp": timestamp,
            "postId": post.id ?? "",
            "postImageUrl": post.imageUrl ?? "",
            "videoUrl": post.videoUrl ?? "",
            "thumbnailUrl": post.thumbnailUrl ?? "",
            "isRead": false // Unread for the receiver
        ]

        let senderRef = COLLECTION_MESSAGES.document(currentUid).collection(user.id).document(messageId)
        let receiverRef = COLLECTION_MESSAGES.document(user.id).collection(currentUid).document(messageId)

        // Save sender's copy
        senderRef.setData(senderData) { error in
            if let error = error {
                print("❌ Failed to save sender's message: \(error.localizedDescription)")
            } else {
                print("✅ Saved sender's message \(messageId)")
            }
        }

        // Save receiver's copy
        receiverRef.setData(receiverData) { error in
            if let error = error {
                print("❌ Failed to save receiver's message: \(error.localizedDescription)")
            } else {
                print("✅ Saved receiver's message \(messageId)")
            }
        }

        // Update sender's recent-messages
        COLLECTION_MESSAGES.document(currentUid).collection("recent-messages").document(user.id).setData(senderData) { error in
            if let error = error {
                print("❌ Failed to save sender's recent message: \(error.localizedDescription)")
            } else {
                print("✅ Saved sender's recent message for user \(user.id)")
            }
        }

        // Update receiver's recent-messages
        COLLECTION_MESSAGES.document(user.id).collection("recent-messages").document(currentUid).setData(receiverData) { error in
            if let error = error {
            print("❌ Failed to save receiver's recent message: \(error.localizedDescription)")
            } else {
                print("✅ Saved receiver's recent message for user \(currentUid)")
            }
        }

        Task {
            await NotificationService.uploadNotification(toUid: user.id, type: .message)
        }
    }
}
