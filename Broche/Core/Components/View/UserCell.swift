//
//  UserCell.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI
import Kingfisher

struct UserCell: View {
    let user: User
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            CircularProfileImageView(user: user, size: .xSmall)
            
            VStack(alignment: .leading, spacing: 2) {
                UsernameWithBadgeView(user: user)   // CHANGED — was plain Text, now shows badge
                
                if let fullname = user.fullname {
                    Text(fullname)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}
