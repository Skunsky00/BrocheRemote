//
//  UsernameWithBadge.swift
//  Broche
//
//  Created by Jacob Johnson on 7/10/25.
//

// Views/UsernameWithBadgeView.swift
import SwiftUI

struct UsernameWithBadgeView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 4) {
            Text(user.username)
                .font(.headline)
            if user.verificationStatus != .none {
                Image(systemName: user.verificationStatus.badgeSymbol)
                    .foregroundColor(user.verificationStatus.badgeColor)
                    .imageScale(.small)
            }
        }
    }
}
