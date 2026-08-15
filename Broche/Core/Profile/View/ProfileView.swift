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
    @State private var selectedFilter: ProfileFilterSelector? = nil
    @State private var showOverlay = true
    @State private var overlayHeight: CGFloat = 0

    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }

    var body: some View {
        ZStack(alignment: .top) {
            contentView

            if showOverlay {
                VStack(spacing: 0) {
                    ProfileHeaderView(viewModel: viewModel)
                    Divider().padding(.horizontal, 12).opacity(0.3)
                    ProfileFilterView(selectedFilter: $selectedFilter)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                }
                .background(.ultraThinMaterial)
                .cornerRadius(18)
                .padding(.horizontal)
                .padding(.top, 8)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: OverlayHeightKey.self, value: proxy.size.height)
                    }
                )
                .onPreferenceChange(OverlayHeightKey.self) { height in
                    overlayHeight = height
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            // No more floating chevron button here — toggle now lives in the map's bottom bar
        }
        .navigationBarTitle("", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                UsernameWithBadgeView(user: user)
            }
        }
        .onChange(of: selectedFilter) {
            if selectedFilter != nil {
                withAnimation { showOverlay = true }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if let filter = selectedFilter {
            switch filter {
            case .broche:
                ScrollView {
                    LazyVStack { BrocheGridView(user: user) }
                        .padding(.top, overlayHeight)
                }
            case .hearts:
                ScrollView {
                    LazyVStack { PostGridView(config: .likedPosts(user)) }
                        .padding(.top, overlayHeight)
                }
            case .bookmarks:
                ScrollView {
                    LazyVStack { CollectionsView(user: user, disableScrolling: true) }
                        .padding(.top, overlayHeight)
                }
            }
        } else {
            MapViewForUserPins2(
                user: user,
                onToggleOverlay: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showOverlay.toggle()
                    }
                }
            )
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
