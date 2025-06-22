//
//  ProfileHeaderView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        VStack {
            CircularProfileImageView(user: viewModel.user, size: .large)
                .padding(.top, 4)
            
            if let fullname = viewModel.user.fullname {
                Text(fullname)
                    .font(.system(size: 17, weight: .regular))
                    .padding(.vertical, 6)
            }
            
            HStack(spacing: 8) {
                NavigationLink(value: SearchViewModelConfig.followers(viewModel.user.id)) {
                    UserStatView(value: viewModel.user.stats?.followers ?? 0, title: "Followers")
                }
                
                NavigationLink(value: SearchViewModelConfig.following(viewModel.user.id)) {
                    UserStatView(value: viewModel.user.stats?.following ?? 0, title: "Following")
                }
            }
            .padding(.vertical, 3)
            
            ProfileActionButtonView(viewModel: viewModel, showShareSheet: $showShareSheet)
                .padding(.horizontal, 32)
            
            if let bio = viewModel.user.bio {
                Text(bio)
                    .font(.system(size: 15, weight: .regular))
                    .padding(.horizontal)
                    .padding(.vertical, 4)
            }
            
            if let link = viewModel.user.link {
                Text(link)
                    .font(.system(size: 15, weight: .regular))
                    .overlay(
                        TextLinkView(text: link, linkColor: .cyan)
                    )
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .navigationDestination(for: SearchViewModelConfig.self) { config in
            UserListView(config: config)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(username: viewModel.user.username ?? "")
                .presentationDetents([.height(150)])
        }
        .onAppear {
            viewModel.loadUserData()
        }
    }
}

struct ShareSheetView: View {
    let username: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Share Profile")
                .font(.system(size: 17, weight: .medium))
            
            Button(action: {
                let profileLink = "https://travelbroche.com/\(username)"
                UIPasteboard.general.string = profileLink
                dismiss()
            }) {
                Text("Copy Link")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .foregroundColor(.white)
                    .background(Color.cyan)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
}

struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileHeaderView(viewModel: ProfileViewModel(user: User.MOCK_USERS[0]))
    }
}
