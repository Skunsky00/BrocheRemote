//
//  ProfileActionButtonView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/30/23.
//

import SwiftUI

struct ProfileActionButtonView: View {
    @ObservedObject var viewModel: ProfileViewModel
    var isFollowed: Bool { return viewModel.user.isFollowed ?? false }
    @State var showEditProfile = false
    
    var body: some View {
        VStack {
            if viewModel.user.isCurrentUser {
                Button(action: { showEditProfile.toggle() }, label: {
                    Text("Edit Profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 160, height: 32)
                        .foregroundColor(.black)
                        .overlay(RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }).fullScreenCover(isPresented: $showEditProfile) {
                    EditProfileView(user: viewModel.user)
                }
            } else {
                VStack {
                    HStack {
                        Button(action: { isFollowed ? viewModel.unfollow() : viewModel.follow() }, label: {
                            Text(isFollowed ? "Following" : "Follow")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(width: 160, height: 32)
                                .foregroundColor(isFollowed ? .black : .white)
                                .background(isFollowed ? Color.white : Color(.systemCyan))
                                .overlay(RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.gray, lineWidth:isFollowed ? 1 : 0)
                                )
                        }).cornerRadius(3)
                    }
                }
            }
        }
    }
}

struct ProfileActionButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileActionButtonView(viewModel: ProfileViewModel(user: User.MOCK_USERS[0]))
    }
}
