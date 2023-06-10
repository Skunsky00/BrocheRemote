//
//  Constants.swift
//  Broche
//
//  Created by Jacob Johnson on 5/30/23.
//

import Firebase

let COLLECTION_USERS = Firestore.firestore().collection("users")
let COLLECTION_FOLLOWERS = Firestore.firestore().collection("followers")
let COLLECTION_FOLLOWING = Firestore.firestore().collection("following")
let COLLECTION_POSTS = Firestore.firestore().collection("posts")
let COLLECTION_LOCATION = Firestore.firestore().collection("locations")
let COLLECTION_NOTIFICATIONS = Firestore.firestore().collection("notifications")
let COLLECTION_MESSAGES = Firestore.firestore().collection("messages")
