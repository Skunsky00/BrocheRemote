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
    @State private var selectedFilter: ProfileFilterSelector = .map
    @State private var showOverlay = true
    @State private var selectedLocation: Location?
    @Environment(\.dismiss) private var dismiss
    var deepLinkLocationId: String? = nil
    var deepLinkTripId: String? = nil   // NEW
    var deepLinkOpenComments: Bool = false   // NEW

    init(user: User, deepLinkLocationId: String? = nil, deepLinkTripId: String? = nil, deepLinkOpenComments: Bool = false) {
            self.user = user
            self.deepLinkLocationId = deepLinkLocationId
            self.deepLinkTripId = deepLinkTripId
            self.deepLinkOpenComments = deepLinkOpenComments
            self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        }

    var body: some View {
        Group {
            if selectedFilter == .map {
                ZStack(alignment: .top) {
                    MapViewForUserPins2(
                        user: user,
                        showOverlay: $showOverlay,
                        selectedLocation: $selectedLocation,
                        deepLinkLocationId: deepLinkLocationId,
                        deepLinkTripId: deepLinkTripId,   // NEW
                        deepLinkOpenComments: deepLinkOpenComments 
                    )

                    if showOverlay {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 12)
                            ProfileHeaderView(viewModel: viewModel)
                            Divider().padding(.horizontal, 12).opacity(0.3)
                            ProfileFilterBar(selectedFilter: $selectedFilter, isCurrentUser: user.isCurrentUser)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 6)
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(18)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ProfileFilterBar(selectedFilter: $selectedFilter, isCurrentUser: user.isCurrentUser)
                    Divider().opacity(0.3)
                    content
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)   // NEW
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {   // NEW
                Button {
                    if selectedLocation != nil {
                        withAnimation(.spring()) {
                            selectedLocation = nil
                        }
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
            }
            ToolbarItem(placement: .principal) {
                UsernameWithBadgeView(user: user)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedFilter {
        case .map:
            EmptyView()
        case .trips:
            ScrollView {
                SavedTripsListView(user: user)
            }
        case .posts:
            ScrollView {
                PostGridView(config: .profile(user))
            }
        case .hearts:
            ScrollView {
                PostGridView(config: .likedPosts(user))
            }
        }
    }
}

private struct OverlayHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}



struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(user: User.MOCK_USERS[0])
    }
}
