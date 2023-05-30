//
//  ProfileHeaderView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct ProfileHeaderView: View {
    let user: User
    @State private var showEditProfile = false
    
    var body: some View {
        VStack {
            CircularProfileImageView(user: user, size: .large)
            
            if let fullname = user.fullname {
                Text(fullname)
                .font(.system(size: 15, weight: .semibold))
                .padding(.vertical, 6)
        }
            
            HStack(spacing: 24) {
                
                
                UserStatView(value: 3, title: "Followers")
                
                UserStatView(value: 2, title: "Following")
                
            }.padding(.vertical, 4)
            
            // action button
            Button {
                if user.isCurrentUser {
                    showEditProfile.toggle()
                } else {
                        print("Follow user..")
                    }
            } label: {
                Text(user.isCurrentUser ? "Edit Profile" : "Follow")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 160, height: 32)
                    .background(user.isCurrentUser ? .white : Color(.systemCyan))
                    .foregroundColor(user.isCurrentUser ? .black : .white)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 3)
                        .stroke(user.isCurrentUser ? .gray : .clear,lineWidth: 1)
                    )
            }
            
            // bio
            VStack {
                if let bio = user.bio {
                    Text(bio)
                        .font(.footnote)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView(user: user)
        }
    }
}

struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileHeaderView(user: User.MOCK_USERS[0])
    }
}
