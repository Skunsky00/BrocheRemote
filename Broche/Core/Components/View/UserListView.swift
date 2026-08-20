//
//  UserListView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI
import CoreLocation

struct UserListView: View {
    @StateObject var viewModel: SearchViewModel
    private let config: SearchViewModelConfig
    var matchCoordinate: CLLocationCoordinate2D? = nil
    @State private var searchText = ""
    @State private var isEditing = false
    @State private var navigationTarget: FriendVisitTarget?
    @State private var searchTask: Task<Void, Never>?   // NEW

    init(config: SearchViewModelConfig, matchCoordinate: CLLocationCoordinate2D? = nil) {
        self.config = config
        self.matchCoordinate = matchCoordinate
        self._viewModel = StateObject(wrappedValue: SearchViewModel(config: config))
    }

    // CHANGED — picks the right source depending on whether search is active
    var users: [User] {
        searchText.isEmpty ? viewModel.users : viewModel.searchResults
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                SearchBar(text: $searchText, isEditing: $isEditing)

                ForEach(users) { user in
                    Group {
                        if let coordinate = matchCoordinate {
                            Button {
                                Task {
                                    let locId = await UserService.fetchLocationId(uid: user.id, coordinate: coordinate, type: .visited)
                                    navigationTarget = FriendVisitTarget(user: user, locationId: locId)
                                }
                            } label: {
                                UserCell(user: user)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(destination: ProfileView(user: user)) {
                                UserCell(user: user)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .onAppear {
                        if searchText.isEmpty && viewModel.supportsPagination && user.id == users.last?.id {
                            Task { await viewModel.fetchUsers() }
                        }
                    }
                }
            }
            .navigationTitle(config.navigationTitle)
            .padding(.top)
        }
        .navigationDestination(item: $navigationTarget) { target in
            ProfileView(user: target.user, deepLinkLocationId: target.locationId)
        }
        .onChange(of: searchText) { newValue in   // NEW — debounced search trigger
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)   // 300ms debounce
                guard !Task.isCancelled else { return }
                await viewModel.search(newValue)
            }
        }
    }
}
