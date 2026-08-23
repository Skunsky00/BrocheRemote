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
    
    private var isUnread: Bool {   // NEW — single source of truth, used twice below
        !message.isRead && message.fromId != Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let user = message.user {
                CircularProfileImageView(user: user, size: .medium)   // CHANGED — was .small, a bit more presence in a list
            }
            
            VStack(alignment: .leading, spacing: 3) {   // CHANGED — was 4, slightly tighter
                if let user = message.user {
                    Text(user.fullname ?? user.username)   // CHANGED — falls back to username if fullname is empty
                        .font(.subheadline)   // CHANGED — was .footnote, a bit more prominent
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 6) {
                    if let postId = message.postId, !postId.isEmpty {
                        let currentUid = Auth.auth().currentUser?.uid
                        if message.fromId == currentUid {
                            Text("You sent a post")
                                .font(.footnote)
                                .foregroundColor(.secondary)   // NEW — de-emphasized, matches "sent" convention
                                .lineLimit(1)
                        } else {
                            Text("\(message.user?.fullname ?? "Someone") sent you a post")
                                .font(.footnote)
                                .fontWeight(isUnread ? .semibold : .regular)   // CHANGED — uses shared isUnread
                                .foregroundColor(isUnread ? .primary : .secondary)   // NEW
                                .lineLimit(1)
                        }
                    } else {
                        Text(message.text)
                            .font(.footnote)
                            .fontWeight(message.fromId == Auth.auth().currentUser?.uid ? .regular : (isUnread ? .semibold : .regular))
                            .foregroundColor(isUnread ? .primary : .secondary)   // NEW — read messages fade back
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {   // CHANGED — stacks dot above timestamp instead of inline
                Text(message.timestamp.dateValue().timeAgoDisplay())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if isUnread {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 10)   // NEW — replaces the old Divider-based rhythm with consistent row padding
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

