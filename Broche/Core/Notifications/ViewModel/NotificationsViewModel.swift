//
//  NotificationsViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import SwiftUI
import Firebase

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications = [Notification]()
    @Published var hasNewNotifications = false
    
    init() {
        Task { await updateNotifications() }
    }
    
    func updateNotifications() async {
        notifications = await NotificationService.fetchNotifications()
        
        await withTaskGroup(of: (Int, Notification).self) { group in
            for (index, notification) in notifications.enumerated() {
                group.addTask {
                    let updated = await NotificationService.fetchMetadata(for: notification)
                    return (index, updated)
                }
            }
            for await (index, updated) in group {
                if index < self.notifications.count {
                    self.notifications[index] = updated
                }
            }
        }
        
        checkForNewNotifications()
    }
    
    private func checkForNewNotifications() {
        let unviewedNotifications = notifications.filter { !$0.isViewed }
        hasNewNotifications = !unviewedNotifications.isEmpty
    }
    
    func markNotificationAsViewed(notification: Notification) {
        NotificationService.markNotificationAsViewed(notification: notification)
    }
}
