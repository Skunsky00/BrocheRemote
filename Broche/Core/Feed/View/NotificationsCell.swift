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

    var isFollowed: Bool {
        return notification.isFollowed ?? false
    }

    init(notification: Binding<Notification>) {
        self.viewModel = NotificationCellViewModel(notification: notification.wrappedValue)
        self._notification = notification
    }

    var body: some View {
        HStack {
            if let user = notification.user {
                NavigationLink(destination: ProfileView(user: user)) {
                    CircularProfileImageView(user: user, size: .xSmall)
                    
                    VStack(alignment: .leading) {
                        Text(user.username)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        
                        if notification.type == .comment {
                            Text("commented on one of your posts.")
                                .font(.system(size: 14))
                        } else if notification.type == .locationComment {
                            if let city = notification.city {
                                Text("commented on your \(city) pin.")
                                    .font(.system(size: 14))
                            } else {
                                Text("commented on one of your locations.")
                                    .font(.system(size: 14))
                            }
                        } else if notification.type == .message {
                            Text("sent you a new message.")
                                .font(.system(size: 14))
                        } else {
                            Text(notification.type.notificationMessage)
                                .font(.system(size: 14))
                        }
                    }
                    .multilineTextAlignment(.leading)

                    Spacer() // Add a spacer to push the timestamp to the right edge of the cell

                    Text(" \(viewModel.timestampString)")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
            }



            Spacer()

            if notification.type != .follow {
                if let post = notification.post {
                    NavigationLink(destination: FeedCell(viewModel: FeedCellViewModel(post: post), player: AVPlayer())) {
                        if let imageUrl = post.imageUrl {
                            KFImage(URL(string: imageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                        } else if let videoUrlString = post.videoUrl, let videoUrl = URL(string: videoUrlString) {
                            VideoThumbnail(url: videoUrl)
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                        }
                    }
                }
            } else {
                Button(action: {
                    isFollowed ? viewModel.unfollow() : viewModel.follow()
                    notification.isFollowed?.toggle()
                }, label: {
                    Text(isFollowed ? "Following" : "Follow")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 100, height: 32)
                        .foregroundColor(isFollowed ? .black : .white)
                        .background(isFollowed ? Color.white : Color.blue)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray, lineWidth: isFollowed ? 1 : 0)
                        )
                })
            }
            if notification.type == .locationComment {
                            Image(systemName: "mappin")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                        }
        }
        .padding(.horizontal)
    }
}


