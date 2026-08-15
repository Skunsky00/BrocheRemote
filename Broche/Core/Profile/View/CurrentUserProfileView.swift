//
//  CurrentUserProfileView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct CurrentUserProfileView: View {
    let user: User
    @StateObject var viewModel: ProfileViewModel
    @StateObject var notiViewModel: NotificationsViewModel
    @State private var showSettingsSheet = false
    @State private var selectedSettingsOption: SettingsItemModel?
    @State private var selectedSettingsPrivacy: SettingsPrivacyModel?
    @State private var showDetail = false
    @State private var selectedFilter: ProfileFilterSelector? = nil  // nil = map is showing
    @State private var showOverlay = true
    @State private var overlayHeight: CGFloat = 0
    @StateObject var brocheViewModel: BrocheGridViewModel
    @Environment(\.colorScheme) var colorScheme

    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self._notiViewModel = StateObject(wrappedValue: NotificationsViewModel())
        self._brocheViewModel = StateObject(wrappedValue: BrocheGridViewModel(user: user))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - Base layer: map or grid content
                contentView

                // MARK: - Floating overlay: header + filter
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
            .environmentObject(brocheViewModel)
            .navigationDestination(isPresented: $showDetail) {
                if let option = selectedSettingsOption {
                    switch option {
                    case .settings:
                        NavigationView {
                            SettingsAndPrivacyView(user: user, selectedOption: $selectedSettingsPrivacy)
                                .navigationTitle("Settings")
                        }
                    case .yourPost:
                        ScrollView {
                            PostGridView(config: .profile(user))
                        }
                    default:
                        Text(option.title)
                    }
                }
            }
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView(selectedOption: $selectedSettingsOption)
                    .presentationDetents([.height(CGFloat(SettingsItemModel.allCases.count * 56))])
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    UsernameWithBadgeView(user: user)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        NotificationsView(viewModel: notiViewModel)
                    } label: {
                        Image(systemName: notiViewModel.hasNewNotifications ? "bell.badge" : "bell")
                            .foregroundColor(notiViewModel.hasNewNotifications ? .red : (colorScheme == .dark ? .white : .black))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedSettingsOption = nil
                        showSettingsSheet.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }
            .onChange(of: notiViewModel.hasNewNotifications) {
                print("DEBUG: CurrentUserProfileView - hasNewNotifications: \(notiViewModel.hasNewNotifications)")
            }
            .onChange(of: selectedSettingsOption) {
                guard let option = selectedSettingsOption else { return }
                switch option {
                case .logout:
                    AuthService.shared.signout()
                case .yourPost, .settings:
                    showDetail = true
                }
            }
            .onChange(of: selectedFilter) {
                if selectedFilter != nil {
                    withAnimation { showOverlay = true }
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if let filter = selectedFilter {
            switch filter {
            case .broche:
                ScrollView {
                    LazyVStack {
                        BrocheGridView(user: user)
                    }
                    .padding(.top, overlayHeight)
                }

            case .hearts:
                ScrollView {
                    LazyVStack {
                        PostGridView(config: .likedPosts(user))
                    }
                    .padding(.top, overlayHeight)
                }

            case .bookmarks:
                ScrollView {
                    LazyVStack {
                        CollectionsView(user: user, disableScrolling: true)
                    }
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

struct CurrentUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentUserProfileView(user: User.MOCK_USERS[0])
    }
}
