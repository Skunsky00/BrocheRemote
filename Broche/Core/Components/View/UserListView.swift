//
//  UserListView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI

struct UserListView: View {
    @StateObject var viewModel: SearchViewModel
    private let config: SearchViewModelConfig
    @State private var searchText = ""
    @State private var isEditing = false
    
    init(config: SearchViewModelConfig) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: SearchViewModel(config: config))
    }
    
    var users: [User] {
        return searchText.isEmpty ? viewModel.users : viewModel.filteredUsers(searchText)
    }
    
    var body: some View {
            ScrollView {
                LazyVStack {
                    SearchBar(text: $searchText, isEditing: $isEditing) // Create a custom SearchBar view.
                        .onSubmit {
                                viewModel.clearUsers()
                                viewModel.updateSearchQuery(searchText)
                            }
                    
                    ForEach(users) { user in
                        NavigationLink(value: user) {
                            UserCell(user: user)
                                .padding(.leading)
                                .onAppear {
                                    if user.id == users.last?.id ?? "" {
                                    }
                                }
                        }
                    }
                }
                .navigationTitle(config.navigationTitle)
                .padding(.top)
            }
        }
    }
