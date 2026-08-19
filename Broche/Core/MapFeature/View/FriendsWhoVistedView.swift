//
//  FriendsWhoVistedView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/17/26.
//

import SwiftUI
import CoreLocation

struct FriendVisitTarget: Identifiable, Hashable {
    let id = UUID()
    let user: User
    let locationId: String?
}

struct FriendsWhoVisitedView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var friends: [User] = []
    @State private var isLoading = false
    @State private var hasChecked = false
    @State private var navigationTarget: FriendVisitTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !hasChecked {
                Button {
                    Task { await check() }
                } label: {
                    Label("See friends who've been here", systemImage: "person.2.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            } else if isLoading {
                ProgressView()
            } else if friends.isEmpty {
                Text("No friends have been here yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    ForEach(friends.prefix(5)) { friend in
                        Button {
                            Task {
                                let locId = await UserService.fetchLocationId(uid: friend.id, coordinate: coordinate, type: .visited)
                                navigationTarget = FriendVisitTarget(user: friend, locationId: locId)
                            }
                        } label: {
                            CircularProfileImageView(user: friend, size: .xSmall)
                        }
                    }
                    Text("been here too")
                        .font(.footnote.bold())
                        .foregroundStyle(.blue)
                }
            }
        }
        .navigationDestination(item: $navigationTarget) { target in
            ProfileView(user: target.user, deepLinkLocationId: target.locationId)
        }
    }

    private func check() async {
        hasChecked = true
        isLoading = true
        friends = await UserService.fetchFriendsWhoVisited(coordinate: coordinate)
        isLoading = false
    }
}
