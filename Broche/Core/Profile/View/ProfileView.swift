//
//  ProfileView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct ProfileView: View {
    let user: User
        
    
    var body: some View {
            ScrollView {
                //header
                ProfileHeaderView(user: user)
                //profile filter bar
                ProfileFilterView()
                // post grid view
                PostGridView(user: user)
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
