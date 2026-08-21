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
    @Published var groupedNotifications: [GroupedNotification] = []
    
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
        buildGroups()
    }
    
    private func checkForNewNotifications() {
        let unviewedNotifications = notifications.filter { !$0.isViewed }
        hasNewNotifications = !unviewedNotifications.isEmpty
    }
    
    func markNotificationAsViewed(notification: Notification) {
        NotificationService.markNotificationAsViewed(notification: notification)
    }
    
    private func buildGroups() {
        var buckets: [String: [Notification]] = [:]
        var order: [String] = []

        for notification in notifications {
            let key = groupingKey(for: notification)
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            buckets[key]?.append(notification)
        }

        var results: [GroupedNotification] = []

        for key in order {
            guard let bucket = buckets[key], !bucket.isEmpty else { continue }
            let sorted = bucket.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
            let newest = sorted[0]

            // Standalone cell — always exactly one user, the most recent actor
            results.append(GroupedNotification(
                id: newest.id ?? UUID().uuidString,
                type: newest.type,
                users: [newest.user].compactMap { $0 },
                latestTimestamp: newest.timestamp,
                representativeNotification: newest,
                isViewed: newest.isViewed
            ))

            // Summary cell — only for like/comment, only the OTHER unique people, excluding the newest actor
            if newest.type == .like || newest.type == .comment {
                var seenUids = Set<String>([newest.uid])   // exclude the newest actor from the summary
                var summaryUsers: [User] = []
                for notification in sorted.dropFirst() {
                    guard !seenUids.contains(notification.uid), let user = notification.user else { continue }
                    seenUids.insert(notification.uid)
                    summaryUsers.append(user)
                }

                if !summaryUsers.isEmpty {
                    let oldestInSummary = sorted.dropFirst().last ?? newest
                    results.append(GroupedNotification(
                        id: "\(key)-summary",
                        type: newest.type,
                        users: summaryUsers,
                        latestTimestamp: oldestInSummary.timestamp,
                        representativeNotification: oldestInSummary,
                        isViewed: sorted.dropFirst().allSatisfy { $0.isViewed }
                    ))
                }
            }
        }

        groupedNotifications = results
    }
    
    private func groupingKey(for notification: Notification) -> String {
        switch notification.type {
        case .like, .comment:
            return "\(notification.type.rawValue)-\(notification.postId ?? notification.id ?? UUID().uuidString)"
        case .locationComment:
            return "\(notification.type.rawValue)-\(notification.locationId ?? notification.id ?? UUID().uuidString)"
        case .follow:
            return "follow-\(notification.id ?? UUID().uuidString)"   // CHANGED — no longer shared, each stays standalone
        case .newPin, .message:
            return notification.id ?? UUID().uuidString
        }
    }
}
