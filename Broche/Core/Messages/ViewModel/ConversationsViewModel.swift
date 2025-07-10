//
//  ConversationsViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI
import Firebase
import FirebaseAuth

class ConversationsViewModel: ObservableObject {
    @Published var recentMessages = [Message]()
    
    func fetchRecentMessages() async throws -> [Message] {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No current user UID")
            return []
        }

        let query = COLLECTION_MESSAGES
            .document(uid)
            .collection("recent-messages")
            .order(by: "timestamp", descending: true)
        
        let snapshot = try await query.getDocuments()
        let messages = snapshot.documents.compactMap { doc -> Message? in
            do {
                return try doc.data(as: Message.self)
            } catch {
                print("❌ Failed to decode message \(doc.documentID): \(error.localizedDescription)")
                return nil
            }
        }
        print("✅ Fetched \(messages.count) recent messages from Firestore")
        return messages
    }
    
    @MainActor
    func loadData() {
        Task {
            print("🔄 Loading recent messages...")
            
            let messages = try await fetchRecentMessages()
            print("✅ Found \(messages.count) recent messages")
            
            var updatedMessages = [Message]()
            for message in messages {
                print("📨 Message from \(message.fromId) to \(message.toId): \(message.text), timestamp: \(message.timestamp.dateValue()), isRead: \(message.isRead), postId: \(String(describing: message.postId))")
                
                let user = try await UserService.fetchUser(withUid: message.chatPartnerId)
                var updatedMessage = message
                updatedMessage.user = user
                updatedMessages.append(updatedMessage)
            }
            
            self.recentMessages = updatedMessages
            print("📬 Final recentMessages count: \(self.recentMessages.count)")
            for message in self.recentMessages {
                print("🔔 Final message order - ID: \(message.id ?? "unknown"), timestamp: \(message.timestamp.dateValue()), postId: \(String(describing: message.postId)), isRead: \(message.isRead)")
            }
        }
    }
}
