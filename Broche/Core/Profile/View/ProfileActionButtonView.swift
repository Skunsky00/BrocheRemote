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
    
    private var buttonLabel: String {
           if viewModel.user.isCurrentUser {
               return "Edit Profile"
           } else if isFollowed {
               return "Following"
           } else if viewModel.followsMe {
               return "Follow Back"   // NEW — reciprocal state
           } else {
               return "Follow"
           }
       }
    
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 4/255, green: 43/255, blue: 68/255),
            Color(red: 197/255, green: 70/255, blue: 99/255),
            Color(red: 255/255, green: 104/255, blue: 102/255),
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
            HStack(spacing: 10) {
                Button(action: {
                    if viewModel.user.isCurrentUser {
                        showEditProfile.toggle()
                    } else {
                        isFollowed ? viewModel.unfollow() : viewModel.follow()
                    }
                }) {
                    Text(buttonLabel)   // CHANGED
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundColor(primaryButtonForeground)
                        .background(primaryButtonBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .fullScreenCover(isPresented: $showEditProfile) {
                    EditProfileView(user: viewModel.user) { updatedUser in
                        viewModel.user = updatedUser
                    }
                }

                Button(action: {
                    showShareSheet.toggle()
                }) {
                    Text("Share")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundColor(.white)
                        .background(gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }

        private var primaryButtonForeground: Color {
            if viewModel.user.isCurrentUser || isFollowed {
                return colorScheme == .dark ? .white : .black
            }
            return .white
        }

        private var primaryButtonBackground: some View {
            Group {
                if viewModel.user.isCurrentUser || isFollowed {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemBackground))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cyan)
                }
            }
        }
    }
//struct ProfileActionButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileActionButtonView(viewModel: ProfileViewModel(user: User.MOCK_USERS[0]))
//    }
//}
