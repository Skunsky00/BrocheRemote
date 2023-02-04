//
//  UserListView.swift
//  Broche
//
//  Created by Jacob Johnson on 12/13/22.
//

import SwiftUI

struct UserListView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Binding var searchText: String
    
    var users: [User] {
        return searchText.isEmpty ? viewModel.users : viewModel.filteredUsers(searchText)
    }
    var body: some View {
        ScrollView {
            LazyVStack{
                ForEach(users) { user in
                    NavigationLink(
                        destination: ProfileView2(user: user),
                        label: {
                            UserCell(user: user)
                                .padding(.leading)
                    })
                }
            }
        }
    }
}


