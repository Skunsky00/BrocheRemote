//
//  NotificationService.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import Firebase
import FirebaseFirestore
import FirebaseAuth

struct NotificationService {
    
    static func fetchNotifications() async -> [Notification] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        
        let query = COLLECTION_NOTIFICATIONS
            .document(uid).collection("user-notifications")
            .order(by: "timestamp", descending: true)
        
        guard let snapshot = try? await query.getDocuments() else { return [] }
        return snapshot.documents.compactMap({ try? $0.data(as: Notification.self) })
    }
    
    static func markNotificationAsViewed(notification: Notification) {
        guard let notificationID = notification.id, let uid = Auth.auth().currentUser?.uid else {
            print("Error: Invalid notification ID or user ID.")
            return
        }
        
        COLLECTION_NOTIFICATIONS
            .document(uid)
            .collection("user-notifications")
            .document(notificationID)
            .updateData(["isViewed": true]) { error in
                if let error = error {
                    print("Error updating notification: \(error)")
                } else {
                    print("Notification marked as viewed successfully.")
                }
            }
    }
    
    static func deleteNotification(toUid uid: String, type: NotificationType, postId: String? = nil) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications")
            .whereField("uid", isEqualTo: currentUid).getDocuments { snapshot, _ in
                snapshot?.documents.forEach({ document in
                    let notification = try? document.data(as: Notification.self)
                    guard notification?.type == type else { return }
                    
                    if postId != nil {
                        guard postId == notification?.postId else { return }
                    }
                    
                    document.reference.delete()
                })
            }
    }
    
    static func uploadNotification(toUid uid: String, type: NotificationType, post: Post? = nil, location: Location? = nil) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard uid != currentUid else { return }
        
        var data: [String: Any] = ["timestamp": Timestamp(date: Date()),
                                   "uid": currentUid,
                                   "type": type.rawValue,
                                   "isViewed": false]
        
        if let post = post, let id = post.id {
            data["postId"] = id
        }
        
        if let location = location {
            data["locationId"] = location.id
            data["city"] = location.city ?? ""
        }
        
        COLLECTION_NOTIFICATIONS.document(uid).collection("user-notifications").addDocument(data: data)
    }
    
    // NEW — fans a "new pin" notification out to everyone following the pin's owner
    static func uploadNewPinNotificationToFollowers(currentUid: String, location: Location) async {
        guard let snapshot = try? await COLLECTION_FOLLOWERS
            .document(currentUid)
            .collection("user-followers")
            .getDocuments() else { return }
        
        for doc in snapshot.documents {
            let followerUid = doc.documentID
            var data: [String: Any] = [
                "timestamp": Timestamp(date: Date()),
                "uid": currentUid,
                "type": NotificationType.newPin.rawValue,
                "isViewed": false,
                "locationId": location.id
            ]
            if let city = location.city {
                data["city"] = city
            }
            try? await COLLECTION_NOTIFICATIONS.document(followerUid).collection("user-notifications").addDocument(data: data)
        }
    }
    
    static func fetchMetadata(for notification: Notification) async -> Notification {
        var updated = notification
        
        async let notificationUser = try? await UserService.fetchUser(withUid: notification.uid)
        updated.user = await notificationUser
        
        if notification.type == .follow {
            async let isFollowed = await UserService.checkIfUserIsFollowed(uid: notification.uid)
            updated.isFollowed = await isFollowed
        }
        
        if let postId = notification.postId {
            async let postSnapshot = await COLLECTION_POSTS.document(postId).getDocument()
            updated.post = try? await postSnapshot.data(as: Post.self)
        }
        
        if let locationId = notification.locationId {
            async let locationSnapshot = await COLLECTION_LOCATION.document(locationId).getDocument()
            updated.location = try? await locationSnapshot.data(as: Location.self)
            if updated.location == nil {
                async let futureLocationSnapshot = await COLLECTION_FUTURE_LOCATIONS.document(locationId).getDocument()
                updated.location = try? await futureLocationSnapshot.data(as: Location.self)
            }
        }
        
        return updated
    }
}
