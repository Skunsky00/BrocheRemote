//
//  CommentViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import SwiftUI
import Firebase

@MainActor
class CommentViewModel: ObservableObject {
    private let post: Post
    private let postId: String
    @Published var comments = [Comment]()
    
    init(post: Post) {
        self.post = post
        self.postId = post.id ?? ""
        
        Task { try await fetchComments() }
    }
    
    func uploadComment(commentText: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let currentUser = AuthService.shared.currentUser else { return }
        
        let data: [String: Any] = ["commentOwnerUid": uid,
                                   "timestamp": Timestamp(date: Date()),
                                   "postOwnerUid": post.ownerUid,
                                   "postId": postId,
                                   "commentText": commentText]
        
        let _ = try? await COLLECTION_POSTS.document(postId).collection("post-comments").addDocument(data: data)
        async let _ = try await COLLECTION_POSTS.document(postId).updateData(["comments": (post.comments ?? 0) + 1])
        NotificationsViewModel.uploadNotification(toUid: self.post.ownerUid, type: .comment, post: self.post)
        self.comments.insert(Comment(user: currentUser, data: data), at: 0)
    }
    
    func fetchComments() async throws {
        let query = COLLECTION_POSTS.document(postId).collection("post-comments").order(by: "timestamp", descending: true)
        guard let commentSnapshot = try? await query.getDocuments() else { return }
        let documentData = commentSnapshot.documents.compactMap({ $0.data() })
        
        for data in documentData {
            guard let uid = data ["commentOwnerUid"] as? String else { return }
            let user = try await UserService.fetchUser(withUid: uid)
            let comment = Comment(user: user, data: data)
            self.comments.append(comment)
        }
    }
}

// MARK: - Deletion

extension CommentViewModel {
    func deleteAllComments() {
        COLLECTION_POSTS.getDocuments { snapshot, _ in
            guard let postIDs = snapshot?.documents.compactMap({ $0.documentID }) else { return }
            
            for id in postIDs {
                COLLECTION_POSTS.document(id).collection("post-comments").getDocuments { snapshot, _ in
                    guard let commentIDs = snapshot?.documents.compactMap({ $0.documentID }) else { return }
                    
                    for commentId in commentIDs {
                        COLLECTION_POSTS.document(id).collection("post-comments").document(commentId).delete()
                    }
                }
            }
        }
    }
}
