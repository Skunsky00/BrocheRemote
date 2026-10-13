//
//  NotificationsView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationsViewModel
    @State private var selectedPost: Post?
    @State private var openComments = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.groupedNotifications.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.groupedNotifications) { group in
                                GroupedNotificationCell(group: group) { post, shouldOpenComments in
                                    openComments = shouldOpenComments
                                    selectedPost = post
                                }
                                .onAppear {
                                    viewModel.markGroupAsViewed(group)
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.updateNotifications()
                    }
                }
            }
            .navigationDestination(item: $selectedPost) { post in
                feedCellDestination(for: post)
            }
            .onAppear {
                viewModel.hasNewNotifications = false
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func feedCellDestination(for post: Post) -> some View {
        if let videoUrl = post.videoUrl, !videoUrl.isEmpty {
            PostGridFeedCell(viewModel: FeedCellViewModel(post: post), autoOpenComments: openComments)
        } else {
            PostGridFeedCellPhoto(viewModel: FeedCellViewModel(post: post), autoOpenComments: openComments)
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
}


