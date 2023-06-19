//
//  NotificationsCell.swift
//  Broche
//
//  Created by Jacob Johnson on 6/19/23.
//

import SwiftUI
import Kingfisher

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
                    
                    HStack {
                        Text(user.username)
                            .font(.system(size: 14, weight: .semibold)) +
                        
                            Text(notification.type.notificationMessage)
                            .font(.system(size: 14)) +
                        
                            Text(" \(viewModel.timestampString)")
                            .foregroundColor(.gray).font(.system(size: 12))
                    }
                    .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
            
            if notification.type != .follow {
                if let post = notification.post {
                    NavigationLink(destination: FeedCell(viewModel: FeedCellViewModel(post: post))) {
                        KFImage(URL(string: post.imageUrl!))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipped()
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
            
        }
        .padding(.horizontal)
    }
}

