//
//  ProfileView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct ProfileView: View {
    let user: User
    @StateObject var viewModel: ProfileViewModel
    @State private var selectedFilter: ProfileFilterSelector = .hearts
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }

        var body: some View {
            ScrollView {
                //header
                ProfileHeaderView(viewModel: viewModel)
                //profile filter bar
                ProfileFilterView(selectedFilter: $selectedFilter)
                // post grid view
                brocheView
            //    PostGridView(config: .profile(user))
            }
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
    }
    
    var brocheView: some View {
        ScrollView {
            LazyVStack {
                switch self.selectedFilter {
                case .hearts:
                    PostGridView(config: .likedPosts(user))
                case .bookmarks:
                    PostGridView(config: .bookmarkedPosts(user))
                case .mappin:
                     MapViewForUserPins()
                }
                
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(user: User.MOCK_USERS[0])
    }
}
