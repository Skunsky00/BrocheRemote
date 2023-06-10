//
//  ConversationCell.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI
import Kingfisher

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
                    
                    Text(message.text)
                        .font(.footnote)
                        .lineLimit(2)
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.trailing)
                
                Spacer()
            }
            
            Divider()
        }
        
    }
}

