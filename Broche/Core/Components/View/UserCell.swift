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
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if let fullname = user.fullname {
                    Text(fullname)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            .font(.footnote)
            .foregroundColor(Color.theme.systemBackground)
            
            Spacer()
        }
        .foregroundColor(.black)
    }
}
