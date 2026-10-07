//
//  NotificationsView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.groupedNotifications.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.groupedNotifications) { group in
                                GroupedNotificationCell(
                                    group: group,
                                    viewModel: NotificationCellViewModel(notification: group.representativeNotification)
                                )
                                .onAppear {
                                    for notification in viewModel.notifications where groupMatches(notification, group) {
                                        viewModel.markNotificationAsViewed(notification: notification)
                                    }
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.updateNotifications()
                    }
                }
            }
            .onAppear {
                viewModel.hasNewNotifications = false
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // iOS 17+
    private var emptyState: some View {
        ContentUnavailableView(
            "No Notifications Yet",
            systemImage: "bell.slash",
            description: Text("When there's activity on your account, you'll see it here.")
        )
    }

    private func groupMatches(_ notification: Notification, _ group: GroupedNotification) -> Bool {
        group.users.contains { $0.id == notification.uid } && notification.type == group.type
    }
}


