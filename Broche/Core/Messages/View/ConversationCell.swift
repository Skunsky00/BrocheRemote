//
//  ConversationCell.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI
import FirebaseAuth

struct ConversationCell: View {
    let message: Message
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 12) {
                if let user = message.user {
                    CircularProfileImageView(user: user, size: .small)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let user = message.user {
                        Text(user.fullname ?? "")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        if let postId = message.postId, !postId.isEmpty {
                            let currentUid = Auth.auth().currentUser?.uid
                            if message.fromId == currentUid {
                                Text("You sent a post")
                                    .font(.footnote)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } else {
                                Text("\(message.user?.fullname ?? "Someone") sent you a post")
                                    .font(.footnote)
                                    .fontWeight(message.isRead ? .regular : .bold)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        } else {
                            Text(message.text)
                                .font(.footnote)
                                .fontWeight(message.fromId == Auth.auth().currentUser?.uid ? .regular : (message.isRead ? .regular : .bold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        
                        Spacer()
                        
                        if !message.isRead && message.fromId != Auth.auth().currentUser?.uid {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .padding(.leading, 4)
                        }
                        
                        Text(message.timestamp.dateValue().timeAgoDisplay())
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.trailing)
                
                Spacer()
            }
            
            Divider()
        }
        .onAppear {
            print("🔔 ConversationCell onAppear - message.postId: \(String(describing: message.postId)), fromId: \(message.fromId), user: \(String(describing: message.user?.fullname)), isRead: \(message.isRead), text: \(message.text)")
        }
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

