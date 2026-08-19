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
    var matchCoordinate: CLLocationCoordinate2D? = nil   // NEW
    @State private var searchText = ""
    @State private var isEditing = false
    @State private var navigationTarget: FriendVisitTarget?   // NEW
    
    init(config: SearchViewModelConfig, matchCoordinate: CLLocationCoordinate2D? = nil) {
        self.config = config
        self.matchCoordinate = matchCoordinate
        self._viewModel = StateObject(wrappedValue: SearchViewModel(config: config))
    }
    
    var users: [User] {
        return searchText.isEmpty ? viewModel.users : viewModel.filteredUsers(searchText)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                SearchBar(text: $searchText, isEditing: $isEditing)

                ForEach(users) { user in
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
            }
            .navigationTitle(config.navigationTitle)
            .padding(.top)
        }
        .navigationDestination(item: $navigationTarget) { target in
            ProfileView(user: target.user, deepLinkLocationId: target.locationId)
        }
    }
}
