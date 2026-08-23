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
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.groupedNotifications) { group in
                        GroupedNotificationCell(
                            group: group,
                            viewModel: NotificationCellViewModel(notification: group.representativeNotification)
                        )
                        //.padding(.top)
                        .onAppear {
                            for notification in viewModel.notifications where groupMatches(notification, group) {
                                viewModel.markNotificationAsViewed(notification: notification)
                            }
                        }
                    }
                }
                .onAppear {
                    viewModel.hasNewNotifications = false
                }
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.inline)
            }
            .refreshable {
                await viewModel.updateNotifications()
            }
        }
    }

    private func groupMatches(_ notification: Notification, _ group: GroupedNotification) -> Bool {
        group.users.contains { $0.id == notification.uid } && notification.type == group.type
    }
}


