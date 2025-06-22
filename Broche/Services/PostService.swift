//
//  PostService.swift
//  Broche
//
//  Created by Jacob Johnson on 5/23/23.
//

import Firebase
import Foundation


struct PostService {
    private let db = Firestore.firestore()
    
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
//    
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


// MARK: - Broche  Pin Post

extension PostService {
    static func fetchPinnedPosts(forUserID id: String) async throws -> [Post] {
        let snapshot = try await COLLECTION_USERS.document(id).collection("user-pinned").getDocuments()
        var posts: [Post] = []
        for doc in snapshot.documents {
            let postId = doc.documentID
            let data = doc.data()
            let position = data["position"] as? Int
            let postSnapshot = try await COLLECTION_POSTS.document(postId).getDocument()
            if var post = try? postSnapshot.data(as: Post.self) {
                post.position = position
                posts.append(post)
            }
        }
        return posts
    }
    
    static func savePinnedPost(_ post: Post, forUserID id: String) async throws {
        guard let postId = post.id, let position = post.position else { return }
        let pinnedRef = COLLECTION_USERS.document(id).collection("user-pinned")
        try await pinnedRef.document(postId).setData([
            "position": position,
            "timestamp": Timestamp()
        ], merge: true)
    }
    
    static func removePinnedPost(_ postId: String, forUserID id: String) async throws {
        let pinnedRef = COLLECTION_USERS.document(id).collection("user-pinned")
        try await pinnedRef.document(postId).delete()
    }
}

extension PostService {
    static func fetchCollections(userId: String) async throws -> [Collection] {
        do {
            print("Fetching collections for user: \(userId)")
            let snapshot = try await Firestore.firestore().collection("users")
                .document(userId)
                .collection("collections")
                .getDocuments()
            
            let collections = snapshot.documents.compactMap { doc in
                try? doc.data(as: Collection.self)
            }
            
            print("Fetched \(collections.count) collections")
            return collections
        } catch {
            print("Error fetching collections for user \(userId): \(error.localizedDescription)")
            throw error
        }
    }
    
    static func createCollection(userId: String, name: String) async throws -> Collection? {
        do {
            print("Creating collection: \(name) for user: \(userId)")
            let collectionId = UUID().uuidString
            let collection = Collection(
                id: collectionId,
                name: name,
                postIds: [],
                createdAt: Date(),
                thumbnailUrl: nil
            )
            
            try await Firestore.firestore().collection("users")
                .document(userId)
                .collection("collections")
                .document(collectionId)
                .setData([
                    "id": collectionId,
                    "name": name,
                    "postIds": [],
                    "createdAt": ISO8601DateFormatter().string(from: Date()),
                    "thumbnailUrl": NSNull()
                ])
            
            print("Created collection: \(name)")
            return collection
        } catch {
            print("Error creating collection: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func addPostToCollection(userId: String, collectionId: String, postId: String) async throws {
        do {
            let collectionRef = Firestore.firestore().collection("users")
                .document(userId)
                .collection("collections")
                .document(collectionId)
            
            try await collectionRef.updateData([
                "postIds": FieldValue.arrayUnion([postId])
            ])
            print("Added post \(postId) to collection \(collectionId)")
        } catch {
            print("Error adding post to collection: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func removePostFromAllCollections(userId: String, postId: String) async throws {
        do {
            let collectionsSnapshot = try await Firestore.firestore().collection("users")
                .document(userId)
                .collection("collections")
                .whereField("postIds", arrayContains: postId)
                .getDocuments()
            
            for doc in collectionsSnapshot.documents {
                try await doc.reference.updateData([
                    "postIds": FieldValue.arrayRemove([postId])
                ])
            }
            print("Removed post \(postId) from all collections")
        } catch {
            print("Error removing post from collections: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func fetchPostsInCollection(userId: String, collectionId: String) async throws -> [Post] {
        do {
            let collectionSnapshot = try await Firestore.firestore().collection("users")
                .document(userId)
                .collection("collections")
                .document(collectionId)
                .getDocument()
            
            guard let postIds = collectionSnapshot.data()?["postIds"] as? [String], !postIds.isEmpty else {
                return []
            }
            
            let posts = try await fetchPostsByIDs(postIds: postIds)
            print("Fetched \(posts.count) posts for collection \(collectionId)")
            return posts
        } catch {
            print("Error fetching posts in collection: \(error.localizedDescription)")
            throw error
        }
    }
    
    static func isPostInAnyCollection(userId: String, postId: String) async throws -> Bool {
        do {
            let snapshot = try await Firestore.firestore().collection("users")
                .document(userId)
                .collection("collections")
                .whereField("postIds", arrayContains: postId)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
        } catch {
            print("Error checking collections: \(error.localizedDescription)")
            throw error
        }
    }
    
    private static func fetchPostsByIDs(postIds: [String]) async throws -> [Post] {
        let chunks = postIds.chunked(into: 10)
        var posts: [Post] = []
        
        for chunk in chunks {
            let snapshot = try await Firestore.firestore().collection("posts")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            posts.append(contentsOf: snapshot.documents.compactMap { try? $0.data(as: Post.self) })
        }
        
        return posts
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
