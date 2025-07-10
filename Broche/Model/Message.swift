//
//  Message.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import FirebaseFirestoreSwift
import Firebase

struct Message: Identifiable, Hashable, Codable {
    @DocumentID var id: String?
    let fromId: String
    let toId: String
    let timestamp: Timestamp
    let text: String
    let postId: String?
    let postImageUrl: String?
    let videoUrl: String?
    var user: User?
    let isRead: Bool

    var chatPartnerId: String {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case fromId
        case toId
        case timestamp
        case text
        case postId
        case postImageUrl
        case videoUrl
        case user
        case isRead
    }
}
