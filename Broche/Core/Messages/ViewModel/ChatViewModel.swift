//
//  ChatViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI
import Firebase
import FirebaseAuth

class ChatViewModel: ObservableObject {
    let user: User
    @Published var messages = [Message]()
    
    init(user: User) {
        self.user = user
        fetchMessages()
    }
    
    func fetchMessages() {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            print("❌ No current user UID")
            return
        }

        let query = COLLECTION_MESSAGES
            .document(currentUid)
            .collection(user.id)
            .order(by: "timestamp", descending: false)

        query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Error fetching messages: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("❌ No message documents found")
                return
            }

            var newMessages = documents.compactMap { doc -> Message? in
                do {
                    var message = try doc.data(as: Message.self)
                    if message.chatPartnerId != currentUid {
                        message.user = self.user
                    }
                    return message
                } catch {
                    print("❌ Failed to decode message \(doc.documentID): \(error.localizedDescription)")
                    return nil
                }
            }

            self.messages = newMessages
            print("✅ Fetched \(newMessages.count) messages for user \(self.user.id)")

            // Mark only others' messages as read
            for message in newMessages where !message.isRead && message.fromId != currentUid {
                Task {
                    do {
                        let messageRef = COLLECTION_MESSAGES
                            .document(currentUid)
                            .collection(self.user.id)
                            .document(message.id ?? "")
                        
                        try await messageRef.updateData(["isRead": true])
                        print("✅ Marked message \(message.id ?? "unknown") as read in conversation")

                        // Update recent-messages
                        let recentRef = COLLECTION_MESSAGES
                            .document(currentUid)
                            .collection("recent-messages")
                            .document(message.fromId)
                        
                        try await recentRef.updateData(["isRead": true])
                        print("✅ Marked recent message for \(message.fromId) as read")
                    } catch {
                        print("❌ Failed to mark message \(message.id ?? "unknown") as read: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func sendMessage(_ messageText: String) {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            print("❌ No current user UID")
            return
        }
        let uid = user.id
        
        let currentUserRef = COLLECTION_MESSAGES.document(currentUid).collection(uid).document()
        let receivingUserRef = COLLECTION_MESSAGES.document(uid).collection(currentUid)
        let receivingRecentRef = COLLECTION_MESSAGES.document(uid).collection("recent-messages")
        let currentRecentRef = COLLECTION_MESSAGES.document(currentUid).collection("recent-messages")
        
        let messageID = currentUserRef.documentID
        
        let data: [String: Any] = [
            "text": messageText,
            "id": messageID,
            "fromId": currentUid,
            "toId": uid,
            "timestamp": Timestamp(date: Date()),
            "isRead": true // Sender's messages are always read
        ]
        
        let recipientData: [String: Any] = [
            "text": messageText,
            "id": messageID,
            "fromId": currentUid,
            "toId": uid,
            "timestamp": Timestamp(date: Date()),
            "isRead": false // Unread for recipient
        ]
        
        currentUserRef.setData(data) { error in
            if let error = error {
                print("❌ Failed to save message for sender: \(error.localizedDescription)")
            } else {
                print("✅ Saved message \(messageID) for sender")
            }
        }
        currentRecentRef.document(uid).setData(data) { error in
            if let error = error {
                print("❌ Failed to save recent message for sender: \(error.localizedDescription)")
            } else {
                print("✅ Saved recent message for sender")
            }
        }

        receivingUserRef.document(messageID).setData(recipientData) { error in
            if let error = error {
                print("❌ Failed to save message for recipient: \(error.localizedDescription)")
            } else {
                print("✅ Saved message \(messageID) for recipient")
            }
        }
        receivingRecentRef.document(currentUid).setData(recipientData) { error in
            if let error = error {
                print("❌ Failed to save recent message for recipient: \(error.localizedDescription)")
            } else {
                print("✅ Saved recent message for recipient")
            }
        }
        
        Task {
            await NotificationsViewModel.uploadNotification(toUid: uid, type: .message)
        }
    }
}

