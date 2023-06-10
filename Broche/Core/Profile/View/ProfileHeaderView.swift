//
//  ProfileHeaderView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    
    var body: some View {
        VStack {
            CircularProfileImageView(user: viewModel.user, size: .large)
            
            if let fullname = viewModel.user.fullname {
                Text(fullname)
                .font(.system(size: 15, weight: .semibold))
                .padding(.vertical, 6)
        }
            
            HStack(spacing: 24) {
                
                NavigationLink(value: SearchViewModelConfig.followers(viewModel.user.id)) {
                    UserStatView(value: viewModel.user.stats?.followers ?? 0, title: "Followers")
                }
               // .disabled(viewModel.user.stats?.followers == 0)
                
                NavigationLink(value: SearchViewModelConfig.following(viewModel.user.id)) {
                    UserStatView(value: viewModel.user.stats?.following ?? 0, title: "Following")
                }
               // .disabled(viewModel.user.stats?.following == 0)
                
            }.padding(.vertical, 4)
            
            // action button
            ProfileActionButtonView(viewModel: viewModel)
            
            // bio
            VStack {
                if let bio = viewModel.user.bio {
                    Text(bio)
                        .font(.footnote)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        
        }
        .navigationDestination(for: SearchViewModelConfig.self) { config in
            UserListView(config: config)
        }
    }
}

struct ProfileHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileHeaderView(viewModel: ProfileViewModel(user: User.MOCK_USERS[0]))
    }
}
