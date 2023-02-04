//
//  User.swift
//  Broche
//
//  Created by Jacob Johnson on 2/3/23.
//

import FirebaseFirestoreSwift

struct User: Identifiable, Decodable {
    let username: String
    let email: String
    let profileImage: String
    let fullname: String
    @DocumentID var id: String?
    var isFollowed: Bool? = false
    
    
    var isCurrentUser: Bool { return AuthViewModel.shared.userSession?.uid == id }
}
