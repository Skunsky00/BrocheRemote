//
//  GroupedNotificationCellView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/20/26.
//

import SwiftUI
import Kingfisher

struct GroupedNotificationCell: View {
    let group: GroupedNotification
    @ObservedObject var viewModel: NotificationCellViewModel
    @State private var selectedPost: Post?
    @State private var isFollowedState: Bool   // NEW

    private var primaryUser: User? { group.users.first }
    private var extraCount: Int { max(0, group.users.count - 1) }
    
    init(group: GroupedNotification, viewModel: NotificationCellViewModel) {
            self.group = group
            self.viewModel = viewModel
            self._isFollowedState = State(initialValue: group.representativeNotification.isFollowed ?? false)
        }
    
    var body: some View {
        Group {
            if let primaryUser {
                if group.type == .newPin, let locationId = group.representativeNotification.locationId {
                    NavigationLink(destination: ProfileView(user: primaryUser, deepLinkLocationId: locationId)) {
                        cellContent(primaryUser: primaryUser)
                    }
                    .buttonStyle(.plain)
                } else if group.type == .locationComment, let locationId = group.representativeNotification.locationId {
                    if let currentUser = AuthService.shared.currentUser {
                        NavigationLink(destination: ProfileView(user: currentUser, deepLinkLocationId: locationId, deepLinkOpenComments: true)) {
                            cellContent(primaryUser: primaryUser)
                        }
                        .buttonStyle(.plain)
                    }
                } else if group.type == .message {
                    NavigationLink(destination: ChatView(user: primaryUser)) {
                        cellContent(primaryUser: primaryUser)
                    }
                    .buttonStyle(.plain)
                } else if group.type == .comment, let post = group.representativeNotification.post {
                    Button {
                        selectedPost = post
                    } label: {
                        cellContent(primaryUser: primaryUser)
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink(destination: ProfileView(user: primaryUser)) {
                        cellContent(primaryUser: primaryUser)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(group.isViewed ? Color(.secondarySystemBackground) : Color.blue.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(group.isViewed ? Color.clear : Color.blue.opacity(0.25), lineWidth: 1)
        )
        .navigationDestination(item: $selectedPost) { post in
            feedCellDestination(for: post)
        }
    }

    private var isStandalone: Bool {
        !group.id.hasSuffix("-summary")
    }

    @ViewBuilder
    private func cellContent(primaryUser: User) -> some View {
        HStack(spacing: 12) {
            avatarStack

            VStack(alignment: .leading, spacing: 3) {
                if isStandalone {
                    (
                        Text(primaryUser.username).fontWeight(.semibold)
                        + Text("  " + soloMessageText())
                    )
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                } else {
                    (
                        Text(primaryUser.username).fontWeight(.semibold)
                        + Text(group.users.count > 1 ? " and \(group.users.count - 1) other\(group.users.count - 1 == 1 ? "" : "s")  " : "  ")
                        + Text(summaryMessageText())
                    )
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                }

                Text(timestampString())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            trailingContent()
        }
    }

    private func soloMessageText() -> String {
        switch group.type {
        case .like: return "liked your post."
        case .comment:
            if let text = group.representativeNotification.commentText, !text.isEmpty {
                let truncated = text.count > 40 ? String(text.prefix(40)) + "…" : text
                return "commented: \"\(truncated)\""
            }
            return "commented on your post."
        case .locationComment:
            if let text = group.representativeNotification.commentText, !text.isEmpty {
                let truncated = text.count > 40 ? String(text.prefix(40)) + "…" : text
                return "commented: \"\(truncated)\""
            }
            if let city = group.representativeNotification.city {
                return "commented on your \(city) pin."
            }
            return "commented on your location."
        case .follow: return "started following you."
        case .message: return "sent you a new message."
        case .newPin:
            if let city = group.representativeNotification.city {
                return "added a new pin in \(city)."
            }
            return "added a new pin to their map."
        }
    }

    private func summaryMessageText() -> String {
        switch group.type {
        case .like: return "liked your post."
        case .comment: return "also commented on your post."
        default: return "interacted with your post."
        }
    }

    @ViewBuilder
    private var avatarStack: some View {
        HStack(spacing: -16) {
            ForEach(Array(group.users.prefix(3).enumerated()), id: \.element.id) { index, user in
                CircularProfileImageView(user: user, size: .small)
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                    .zIndex(Double(3 - index))
            }
        }
    }

    @ViewBuilder
    private func trailingContent() -> some View {
        if group.type == .follow {
            Button {
                let willFollow = !isFollowedState
                isFollowedState = willFollow
                if willFollow {
                    viewModel.follow()
                } else {
                    viewModel.unfollow()
                }
            } label: {
                Text(isFollowedState ? "Following" : "Follow back")
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(width: 100, height: 34)
                    .foregroundColor(isFollowedState ? .primary : .white)
                    .background(isFollowedState ? Color(.tertiarySystemBackground) : Color.blue)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.gray.opacity(isFollowedState ? 0.3 : 0), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        } else if let post = group.representativeNotification.post {
            Button {
                selectedPost = post
            } label: {
                thumbnail(for: post)
            }
            .buttonStyle(.plain)
        } else if group.type == .newPin || group.type == .locationComment {
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
                KFImage(URL(string: imageUrl)).resizable().scaledToFill()
            } else if let videoUrlString = post.videoUrl, let videoUrl = URL(string: videoUrlString) {
                VideoThumbnail(url: videoUrl).scaledToFill()
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @MainActor
    @ViewBuilder
    private func feedCellDestination(for post: Post) -> some View {
        if let videoUrl = post.videoUrl, !videoUrl.isEmpty {
            PostGridFeedCell(viewModel: FeedCellViewModel(post: post), autoOpenComments: group.type == .comment)
        } else {
            PostGridFeedCellPhoto(viewModel: FeedCellViewModel(post: post), autoOpenComments: group.type == .comment)
        }
    }


    private func timestampString() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: group.latestTimestamp.dateValue(), to: Date()) ?? ""
    }
}
