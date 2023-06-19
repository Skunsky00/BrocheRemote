//
//  NotificationCellViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import SwiftUI

@MainActor
class NotificationCellViewModel: ObservableObject {
    @Published var notification: Notification
    
    var timestampString: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: notification.timestamp.dateValue(), to: Date()) ?? ""
    }
    
    init(notification: Notification) {
        self.notification = notification
    }
    
    func follow() {
        UserService.follow(uid: notification.uid) { _ in
            NotificationsViewModel.uploadNotification(toUid: self.notification.uid, type: .follow)
            self.notification.isFollowed = true
        }
    }
    
    func unfollow() {
        UserService.unfollow(uid: notification.uid) { _ in
            self.notification.isFollowed = false
        }
    }
}
