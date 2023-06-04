//
//  Post.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import Foundation
import Firebase

struct Post: Identifiable, Hashable, Codable {
    let id: String?
    let ownerUid: String
    let caption: String
    let location: String
    var likes: Int
    let imageUrl: String?
    let videoUrl: String?
    let label: String
    let timestamp: Timestamp
    var user: User?
    
    var didLike: Bool? = false
    var didBookmark: Bool? = false
}

extension Post {
    static var MOCK_POSTS: [Post] = [
        .init(
        id: NSUUID().uuidString,
        ownerUid:NSUUID().uuidString,
        caption: "creator of broche",
        location: "Orlando, Fl",
        likes: 195,
        imageUrl: "example",
        videoUrl: nil,
        label: "Air BnB",
        timestamp: Timestamp(),
        user: User.MOCK_USERS[0]
        ),
        .init(
        id: NSUUID().uuidString,
        ownerUid:NSUUID().uuidString,
        caption: "Im batman, ill steal your girl anytome of the night",
        location: "Gothom,  IL",
        likes: 130,
        imageUrl: "example",
        videoUrl: nil,
        label: "Air BnB",
        timestamp: Timestamp(),
        user: User.MOCK_USERS[1]
        ),
        .init(
        id: NSUUID().uuidString,
        ownerUid:NSUUID().uuidString,
        caption: "I am Iron Man",
        location: "Los Angelos, CA",
        likes: 12232,
        imageUrl: "example",
        videoUrl: nil,
        label: "Air BnB",
        timestamp: Timestamp(),
        user: User.MOCK_USERS[2]
        ),
        .init(
        id: NSUUID().uuidString,
        ownerUid:NSUUID().uuidString,
        caption: "I am hulk smash",
        location: "New York, NY",
        likes: 16433,
        imageUrl: "example",
        videoUrl: nil,
        label: "Air BnB",
        timestamp: Timestamp(),
        user: User.MOCK_USERS[3]
        ),
        .init(
        id: NSUUID().uuidString,
        ownerUid:NSUUID().uuidString,
        caption: "I am thor got of tunder",
        location: "Asgard",
        likes: 13,
        imageUrl: "example",
        videoUrl: nil,
        label: "Hotle",
        timestamp: Timestamp(),
        user: User.MOCK_USERS[4]
        ),
    ]
}
