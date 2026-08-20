//
//  NewMessageView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI

struct NewMessageView: View {
    @State var searchText = ""
    @Binding var show: Bool
    @Binding var startChat: Bool
    @Binding var user: User?
    @StateObject private var viewModel = SearchViewModel(config: .newMessage)   // CHANGED — see note below
    @State private var searchTask: Task<Void, Never>?   // NEW

    var displayedUsers: [User] {   // CHANGED — no more filteredUsers call
        searchText.isEmpty ? viewModel.users : viewModel.searchResults
    }

    var body: some View {
        ScrollView {
            SearchBar(text: $searchText, isEditing: .constant(false))
                .padding()

            LazyVStack(alignment: .leading) {
                ForEach(displayedUsers) { selectedUser in   // CHANGED — renamed to avoid shadowing @Binding var user
                    HStack { Spacer() }

                    Button(action: {
                        self.show.toggle()
                        self.startChat.toggle()
                        self.user = selectedUser
                    }, label: {
                        UserCell(user: selectedUser)
                    })
                    .onAppear {
                        if searchText.isEmpty && viewModel.supportsPagination && selectedUser.id == viewModel.users.last?.id {
                            Task { await viewModel.fetchUsers() }
                        }
                    }
                }
            }
            .padding(.leading)
        }
        .onChange(of: searchText) { newValue in   // NEW — same debounce pattern as UserListView
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                await viewModel.search(newValue)
            }
        }
    }
}
