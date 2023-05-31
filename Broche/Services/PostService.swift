//
//  PostService.swift
//  Broche
//
//  Created by Jacob Johnson on 5/23/23.
//

import Firebase

struct PostService {
    static func fetchPost() async throws -> [Post] {
        let snapshot = try await COLLECTION_POSTS.getDocuments()
        var posts = try snapshot.documents.compactMap({ try $0.data(as: Post.self) })

        for i in 0 ..< posts.count {
            let post = posts[i]
            let ownerUid = post.ownerUid
            let postUser = try await UserService.fetchUser(wtihUid: ownerUid)
            posts[i].user = postUser
        }

        return posts
    }
//
//    static func fetchUserPosts(uid: String) async throws -> [Post] {
//        let snapshot = try await COLLECTION_POSTS.whereField("ownerUid", isEqualTo: uid).getDocuments()
//        return try snapshot.documents.compactMap({ try $0.data(as: Post.self) })
//    }
//}


//static func fetchPost(withId id: String) async throws -> Post {
//    let postSnapshot = try await COLLECTION_POSTS.document(id).getDocument()
//    let post = try postSnapshot.data(as: Post.self)
//    return post
//}

static func fetchUserPosts(user: User) async throws -> [Post] {
    let snapshot = try await COLLECTION_POSTS.whereField("ownerUid", isEqualTo: user.id).getDocuments()
    var posts = snapshot.documents.compactMap({try? $0.data(as: Post.self )})
    
    for i in 0 ..< posts.count {
        posts[i].user = user
    }
    
    return posts
}
}
