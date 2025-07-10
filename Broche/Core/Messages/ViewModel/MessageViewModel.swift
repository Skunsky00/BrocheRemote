//
//  MessageViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import Firebase

struct MessageViewModel {
    let message: Message
    
    var currentUid: String { return Auth.auth().currentUser?.uid ?? "" }
    
    var isFromCurrentUser: Bool { return message.fromId == currentUid }
    
    var postId: String? { return message.postId }
    var postImageUrl: String? { return message.postImageUrl }
    var videoUrl: String? { return message.videoUrl }
}
