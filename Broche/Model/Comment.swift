//
//  Comment.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import Firebase
import FirebaseFirestoreSwift

struct Comment: Identifiable, Codable {
    let id: String
    let username: String
    let postOwnerUid: String
    let profileImageUrl: String
    let commentText: String
    let postId: String
    let timestamp: Timestamp
    let commentOwnerUid: String
    var likes: [String]   // NEW — uids who liked this comment

    init(id: String, user: User, data: [String: Any]) {   // CHANGED — id now passed in, not generated
        self.id = id
        self.username = user.username
        self.profileImageUrl = user.profileImageUrl ?? ""
        self.postOwnerUid = data["postOwnerUid"] as? String ?? ""
        self.commentText = data["commentText"] as? String ?? ""
        self.postId = data["postId"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
        self.commentOwnerUid = data["commentOwnerUid"] as? String ?? ""
        self.likes = data["likes"] as? [String] ?? []   // NEW
    }

    var timestampString: String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timestamp.dateValue(), to: Date()) ?? ""
    }

    func didLike(uid: String?) -> Bool {   // NEW
        guard let uid else { return false }
        return likes.contains(uid)
    }
}

struct LocationComment: Identifiable, Codable {
    let id: String
    let username: String
    let locationOwnerUid: String
    let profileImageUrl: String
    let commentText: String
    let locationId: String
    let timestamp: Timestamp
    let commentOwnerUid: String
    var likes: [String]   // NEW

    init(id: String, user: User, data: [String: Any]) {   // CHANGED
        self.id = id
        self.username = user.username
        self.profileImageUrl = user.profileImageUrl ?? ""
        self.locationOwnerUid = data["locationOwnerUid"] as? String ?? ""
        self.commentText = data["commentText"] as? String ?? ""
        self.locationId = data["locationId"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
        self.commentOwnerUid = data["commentOwnerUid"] as? String ?? ""
        self.likes = data["likes"] as? [String] ?? []   // NEW
    }

    var timestampString: String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timestamp.dateValue(), to: Date()) ?? ""
    }

    func didLike(uid: String?) -> Bool {   // NEW
        guard let uid else { return false }
        return likes.contains(uid)
    }
}
