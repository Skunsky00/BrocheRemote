//
//  ProfileActionButtonView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/30/23.
//

import SwiftUI

struct ProfileActionButtonView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var showShareSheet: Bool
    @State private var showEditProfile = false
    @Environment(\.colorScheme) var colorScheme
    
    var isFollowed: Bool { return viewModel.user.isFollowed ?? false }
    
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 4/255, green: 43/255, blue: 68/255),
            Color(red: 197/255, green: 70/255, blue: 99/255),
            Color(red: 255/255, green: 104/255, blue: 102/255),
            Color(red: 150/255, green: 90/255, blue: 143/255),
            Color(red: 45/255, green: 61/255, blue: 136/255),
            Color(red: 17/255, green: 55/255, blue: 125/255)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                if viewModel.user.isCurrentUser {
                    showEditProfile.toggle()
                } else {
                    isFollowed ? viewModel.unfollow() : viewModel.follow()
                }
            }) {
                Text(viewModel.user.isCurrentUser ? "Edit Profile" : isFollowed ? "Following" : "Follow")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .foregroundColor(viewModel.user.isCurrentUser || isFollowed ? .black : .white)
                    .background(viewModel.user.isCurrentUser || isFollowed ? Color.white : Color.cyan)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.gray, lineWidth: viewModel.user.isCurrentUser || isFollowed ? 1 : 0)
                    )
            }
            .cornerRadius(3)
            .fullScreenCover(isPresented: $showEditProfile) {
                EditProfileView(user: viewModel.user)
            }
            
            Button(action: {
                showShareSheet.toggle()
            }) {
                Text("Share")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .foregroundColor(.white)
                    .background(gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
            .cornerRadius(3)
        }
        .padding(.vertical, 4)
    }
}

//struct ProfileActionButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileActionButtonView(viewModel: ProfileViewModel(user: User.MOCK_USERS[0]))
//    }
//}
