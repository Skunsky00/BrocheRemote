//
//  Notification.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import FirebaseFirestoreSwift
import Firebase

struct Notification: Identifiable, Decodable {
    @DocumentID var id: String?
    var postId: String?
    var locationId: String?
    var city: String?
    let timestamp: Timestamp
    let type: NotificationType
    let uid: String
    
    var isViewed: Bool = false
    var isFollowed: Bool? = false
    var post: Post?
    var user: User?
    var location: Location?
}

enum NotificationType: Int, Decodable {
    case like
    case comment
    case follow
    case message // New case for message
    case locationComment
    
    var notificationMessage: String {
        switch self {
        case .like: return "liked one of your posts."
        case .comment: return "commented on one of your posts."
        case .follow: return "started following you."
        case .message: return "sent you a new message." // Message-specific notification
        case .locationComment: return "commented on one of your locations."
        }
    }
}

