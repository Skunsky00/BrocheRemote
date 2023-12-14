//
//  PostService.swift
//  Broche
//
//  Created by Jacob Johnson on 5/23/23.
//

import Firebase
import Foundation


struct PostService {
    static func fetchPosts(startingAfter document: DocumentSnapshot?) async throws -> ([Post], DocumentSnapshot?) {
            var query = COLLECTION_POSTS.order(by: "timestamp", descending: true)
            
            if let document = document {
                query = query.start(afterDocument: document)
            }
            
            let snapshot = try await query.limit(to: 5).getDocuments()
            var posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self) })
            
            for i in 0..<posts.count {
                let post = posts[i]
                let ownerUid = post.ownerUid
                let postUser = try await UserService.fetchUser(withUid: ownerUid)
                posts[i].user = postUser
            }
            
            let lastDocument = snapshot.documents.last // Get the last document snapshot
            
            return (posts, lastDocument)
        }

    
    static func fetchUserPosts(user: User) async throws -> [Post] {
        let snapshot = try await COLLECTION_POSTS.whereField("ownerUid", isEqualTo: user.id).getDocuments()
        var posts = snapshot.documents.compactMap({try? $0.data(as: Post.self )})
        
        for i in 0 ..< posts.count {
            posts[i].user = user
        }
        
        return posts
    }
    
    
    static func fetchLikedPosts(forUserID id: String) async throws -> [Post] {
        let snapshot = try await COLLECTION_USERS.document(id).collection("user-likes").getDocuments()
        var posts = snapshot.documents.compactMap({ try? $0.data(as: Post.self) })
        
        let postIDs = snapshot.documents.map({ $0.documentID })
        
        for postID in postIDs {
            let snippet = try await COLLECTION_POSTS.document(postID).getDocument()
            let post = try snippet.data(as: Post.self)
            posts.append(post)
        }
        
        return posts
    }
    
    static func fetchBookmarkedPosts(forUserID id: String) async throws -> [Post] {
        let snapshot = try await COLLECTION_USERS.document(id).collection("user-bookmarks").getDocuments()
        var posts = snapshot.documents.compactMap({try? $0.data(as: Post.self )})
        
        let postIDs = snapshot.documents.map({ $0.documentID })
            
        for postID in postIDs {
            let snippet = try await COLLECTION_POSTS.document(postID).getDocument()
            let post = try snippet.data(as: Post.self)
            posts.append(post)
            
        }
        
        return posts
    }
    
    static func deletePost(_ post: Post) async throws {
            // Delete the post from Firebase
            guard let postId = post.id else { return }
            let postRef = COLLECTION_POSTS.document(postId)
            let userLikesRef = COLLECTION_USERS.document(post.ownerUid).collection("user-likes").document(postId)
            let userBookmarksRef = COLLECTION_USERS.document(post.ownerUid).collection("user-bookmarks").document(postId)
            
            try await postRef.delete()
            try await userLikesRef.delete()
            try await userBookmarksRef.delete()
        }
}

// MARK: - Likes

extension PostService {
    static func likePost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let postId = post.id else { return }
        
        async let _ = try await COLLECTION_POSTS.document(postId).collection("post-likes").document(uid).setData([:])
        async let _ = try await COLLECTION_POSTS.document(postId).updateData(["likes": post.likes + 1])
        async let _ = try await COLLECTION_USERS.document(uid).collection("user-likes").document(postId).setData([:])
        
        async let _ =  await NotificationsViewModel.uploadNotification(toUid: post.ownerUid, type: .like, post: post)
    }
    
    static func unlikePost(_ post: Post) async throws {
        guard post.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let postId = post.id else { return }
        
        async let _ = try await COLLECTION_POSTS.document(postId).collection("post-likes").document(uid).delete()
        async let _ = try await COLLECTION_USERS.document(uid).collection("user-likes").document(postId).delete()
        async let _ = try await COLLECTION_POSTS.document(postId).updateData(["likes": post.likes - 1])
        
        async let _ =  await NotificationsViewModel.deleteNotification(toUid: uid, type: .like, postId: postId)
    }
    
    static func checkIfUserLikedPost(_ post: Post) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        guard let postId = post.id else { return false }
        
        let snapshot = try await COLLECTION_USERS.document(uid).collection("user-likes").document(postId).getDocument()
        return snapshot.exists
    }
}

// MARK: - Bookmarks

extension PostService {
    static func BookmarkPost(_ post: Post) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let postId = post.id else { return }
        
        async let _ = try await COLLECTION_POSTS.document(postId).collection("post-bookmarks").document(uid).setData([:])
//        async let _ = try await COLLECTION_POSTS.document(postId).updateData(["bookmarks": post.likes + 1])
        async let _ = try await COLLECTION_USERS.document(uid).collection("user-bookmarks").document(postId).setData([:])
        
    }
    
    static func unBookmarkPost(_ post: Post) async throws {
        guard post.likes > 0 else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let postId = post.id else { return }
        
        async let _ = try await COLLECTION_POSTS.document(postId).collection("post-bookmarks").document(uid).delete()
        async let _ = try await COLLECTION_USERS.document(uid).collection("user-bookmarks").document(postId).delete()
//        async let _ = try await COLLECTION_POSTS.document(postId).updateData(["bookmarks": post.likes - 1])
        
    }
    
    static func checkIfUserBookmarkedPost(_ post: Post) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        guard let postId = post.id else { return false }
        
        let snapshot = try await COLLECTION_USERS.document(uid).collection("user-bookmarks").document(postId).getDocument()
        return snapshot.exists
    }
}
