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
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }

        var body: some View {
            ScrollView {
                //header
                ProfileHeaderView(viewModel: viewModel)
                //profile filter bar
                ProfileFilterView()
                // post grid view
                PostGridView(config: .profile(user))
            }
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(user: User.MOCK_USERS[0])
    }
}
