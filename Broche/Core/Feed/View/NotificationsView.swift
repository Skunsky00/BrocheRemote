//
//  NotificationsView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import SwiftUI

struct NotificationsView: View {
    @StateObject var viewModel = NotificationsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach($viewModel.notifications) { notification in
                        NotificationCell(notification: notification)
                            .padding(.top)
                            .onAppear {
                                if notification.id == viewModel.notifications.last?.id ?? "" {
                                    print("DEBUG: paginate here..")
                                }
                            }
                    }
                }
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    Task { try await viewModel.updateNotifications() }
                }
            }
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
