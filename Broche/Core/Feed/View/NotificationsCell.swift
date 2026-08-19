//
//  NotificationsCell.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import SwiftUI
import Kingfisher
import AVKit

struct NotificationCell: View {
    @ObservedObject var viewModel: NotificationCellViewModel
    @Binding var notification: Notification
    @State private var selectedPost: Post?
    @Environment(\.colorScheme) var colorScheme

    var isFollowed: Bool {
        return notification.isFollowed ?? false
    }

    init(notification: Binding<Notification>) {
        self.viewModel = NotificationCellViewModel(notification: notification.wrappedValue)
        self._notification = notification
    }

    var body: some View {
        HStack(spacing: 12) {
            if let user = notification.user {
                if notification.type == .newPin, let locationId = notification.locationId {
                    NavigationLink(destination: ProfileView(user: user, deepLinkLocationId: locationId)) {
                        cellContent(user: user)
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(destination: ProfileView(user: user)) {
                        cellContent(user: user)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(notification.isViewed ? Color(.secondarySystemBackground) : Color.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(notification.isViewed ? Color.clear : Color.blue.opacity(0.25), lineWidth: 1)
        )
        .navigationDestination(item: $selectedPost) { post in   // NEW — single, non-nested destination
                    feedCellDestination(for: post)
                }
    }

    @ViewBuilder
    private func cellContent(user: User) -> some View {
        HStack(spacing: 12) {
            CircularProfileImageView(user: user, size: .small)

            VStack(alignment: .leading, spacing: 3) {
                (
                    Text(user.username).fontWeight(.semibold)
                    + Text("  " + messageText())
                )
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

                Text(viewModel.timestampString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            trailingContent()
        }
    }

    @ViewBuilder
    private func trailingContent() -> some View {
        if notification.type == .follow {
            Button {
                isFollowed ? viewModel.unfollow() : viewModel.follow()
                notification.isFollowed?.toggle()
            } label: {
                Text(isFollowed ? "Following" : "Follow")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 92, height: 34)
                    .foregroundColor(isFollowed ? .primary : .white)
                    .background(isFollowed ? Color(.tertiarySystemBackground) : Color.blue)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(isFollowed ? 0.3 : 0), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        } else if let post = notification.post {
            Button {   // CHANGED — was NavigationLink, now a plain Button that sets state
                selectedPost = post
            } label: {
                thumbnail(for: post)
            }
            .buttonStyle(.plain)
        } else if notification.type == .newPin || notification.type == .locationComment {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
        }
    }

    @ViewBuilder
    private func thumbnail(for post: Post) -> some View {
        Group {
            if let imageUrl = post.imageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
            } else if let videoUrlString = post.videoUrl, let videoUrl = URL(string: videoUrlString) {
                VideoThumbnail(url: videoUrl)
                    .scaledToFill()
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    @MainActor
    @ViewBuilder
    func feedCellDestination(for post: Post) -> some View {
        if let videoUrl = post.videoUrl, !videoUrl.isEmpty {
            PostGridFeedCell(viewModel: FeedCellViewModel(post: post))
        } else {
            PostGridFeedCellPhoto(viewModel: FeedCellViewModel(post: post))
        }
    }

    private func messageText() -> String {
        switch notification.type {
        case .comment:
            return "commented on one of your posts."
        case .locationComment:
            if let city = notification.city {
                return "commented on your \(city) pin."
            }
            return "commented on one of your locations."
        case .message:
            return "sent you a new message."
        case .newPin:
            if let city = notification.city {
                return "added a new pin in \(city)."
            }
            return "added a new pin to their map."
        default:
            return notification.type.notificationMessage
        }
    }
}


