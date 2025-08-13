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
    @State private var selectedFilter: ProfileFilterSelector = .broche
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }
    
    var body: some View {
        ScrollView {
            ProfileHeaderView(viewModel: viewModel)
            ProfileFilterView(selectedFilter: $selectedFilter)
            brocheView
        }
        .navigationBarTitle("", displayMode: .inline) // Empty title
        .toolbar {
            ToolbarItem(placement: .principal) {
                UsernameWithBadgeView(user: user)
            }
        }
    }
    
    var brocheView: some View {
        ScrollView {
            LazyVStack {
                switch selectedFilter {
                case .broche:
                    BrocheGridView(user: user)
                case .hearts:
                    PostGridView(config: .likedPosts(user))
                case .bookmarks:
                    CollectionsView(user: user, disableScrolling: true)
                case .mappin:
                    MapViewForUserPins(user: user)
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
