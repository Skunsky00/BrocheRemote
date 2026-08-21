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

        let data: [String: Any] = [
            "commentOwnerUid": uid,
            "timestamp": Timestamp(date: Date()),
            "postOwnerUid": post.ownerUid,
            "postId": postId,
            "commentText": commentText,
            "likes": [String]()   // NEW — start empty
        ]

        guard let ref = try? await COLLECTION_POSTS.document(postId).collection("post-comments").addDocument(data: data) else { return }
        async let _ = try await COLLECTION_POSTS.document(postId).updateData(["comments": (post.comments) + 1])
        NotificationService.uploadNotification(toUid: self.post.ownerUid, type: .comment, post: self.post, commentText: commentText)
        self.comments.insert(Comment(id: ref.documentID, user: currentUser, data: data), at: 0)   // CHANGED — real doc ID
    }

    func fetchComments() async throws {
        let query = COLLECTION_POSTS.document(postId).collection("post-comments").order(by: "timestamp", descending: true)
        guard let commentSnapshot = try? await query.getDocuments() else { return }

        for doc in commentSnapshot.documents {   // CHANGED — iterate docs, not just data(), so we keep documentID
            let data = doc.data()
            guard let uid = data["commentOwnerUid"] as? String else { continue }
            let user = try await UserService.fetchUser(withUid: uid)
            let comment = Comment(id: doc.documentID, user: user, data: data)   // CHANGED
            self.comments.append(comment)
        }
    }

    // NEW — like/unlike
    func toggleLike(_ comment: Comment) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }

        let ref = COLLECTION_POSTS.document(postId).collection("post-comments").document(comment.id)

        if comment.didLike(uid: uid) {
            comments[index].likes.removeAll { $0 == uid }
            try? await ref.updateData(["likes": FieldValue.arrayRemove([uid])])
        } else {
            comments[index].likes.append(uid)
            try? await ref.updateData(["likes": FieldValue.arrayUnion([uid])])
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
