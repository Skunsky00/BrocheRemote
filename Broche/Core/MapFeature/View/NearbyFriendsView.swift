//
//  NearbyFriendsView.swift
//  Broche
//
//  Created by Jacob Johnson on 10/7/26.
//

import SwiftUI
import _LocationEssentials
import CoreLocation


struct NearbyFriendsView: View {
    @StateObject private var viewModel: NearbyFriendsViewModel
    @State private var navigationTarget: FriendVisitTarget?

    init(center: CLLocationCoordinate2D, placeName: String) {
        _viewModel = StateObject(wrappedValue: NearbyFriendsViewModel(center: center, placeName: placeName))
    }

    var body: some View {
        List {
            Section {
                Picker("Radius", selection: $viewModel.radiusMiles) {
                    Text("10 mi").tag(10.0)
                    Text("25 mi").tag(25.0)
                    Text("50 mi").tag(50.0)
                    Text("100 mi").tag(100.0)
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            if viewModel.isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .listRowBackground(Color.clear)
            } else if viewModel.groups.isEmpty {
                ContentUnavailableView(
                    "No friends nearby",
                    systemImage: "mappin.slash",
                    description: Text("None of the people you follow have been within \(Int(viewModel.radiusMiles)) miles of \(viewModel.placeName).")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.groups) { group in
                    Section {
                        ForEach(group.visits) { visit in
                            Button {
                                navigationTarget = FriendVisitTarget(user: group.user, locationId: visit.locationId)
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.circle.fill").foregroundStyle(.red)
                                    VStack(alignment: .leading) {
                                        Text(visit.name).font(.subheadline.bold())
                                        Text(String(format: "%.0f mi away", visit.distanceMiles))
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption).foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        UserCell(user: group.user)
                            .textCase(nil)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .navigationTitle("Friends Nearby")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $navigationTarget) { target in
            ProfileView(user: target.user, deepLinkLocationId: target.locationId)
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.radiusMiles) { _ in
            Task { await viewModel.load() }
        }
    }
}

