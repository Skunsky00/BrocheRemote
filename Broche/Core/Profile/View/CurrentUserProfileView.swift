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
    @State private var selectedFilter: ProfileFilterSelector = .map
    @State private var showOverlay = true
    @State private var selectedLocation: Location?   // NEW — required by MapViewForUserPins2
    @StateObject var brocheViewModel: BrocheGridViewModel
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var pushBadgeState = PushBadgeState.shared   // NEW

    private var showUnreadMessageBadge: Bool {
            notiViewModel.hasUnreadMessages || pushBadgeState.hasUnreadMessages   // NEW
        }
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self._notiViewModel = StateObject(wrappedValue: NotificationsViewModel())
        self._brocheViewModel = StateObject(wrappedValue: BrocheGridViewModel(user: user))
    }
    
    private var showTopBar: Bool {
        selectedFilter != .map || showOverlay
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if selectedFilter == .map {
                    // MODE 1 — full-screen map, header floats on top
                    ZStack(alignment: .top) {
                        MapViewForUserPins2(
                            user: user,
                            showOverlay: $showOverlay,
                            selectedLocation: $selectedLocation   // NEW
                                                )
                        
                        if showOverlay {
                            VStack(spacing: 0) {
                                Spacer().frame(height: 12)
                                ProfileHeaderView(viewModel: viewModel)
                                    .id(viewModel.user.profileImageUrl)   // NEW — forces a fresh header whenever the picture URL changes
                                Divider().padding(.horizontal, 12).opacity(0.3)
                                ProfileFilterBar(selectedFilter: $selectedFilter, isCurrentUser: true)
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
                    // MODE 2 — pinned filter bar at top, content flows below
                    VStack(spacing: 0) {
                        ProfileFilterBar(selectedFilter: $selectedFilter, isCurrentUser: true)
                        Divider().opacity(0.3)
                        content
                    }
                }
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
                    case .bookmark:
                        ScrollView {
                                        CollectionsView(user: user, disableScrolling: true)
                                    }
                    case .emptyView:
                        EmptyView()
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
                ToolbarItem(placement: .navigationBarLeading) {   // NEW
                    if selectedLocation != nil {
                        Button {
                            withAnimation(.spring()) {
                                selectedLocation = nil
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    UsernameWithBadgeView(user: user)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            ConversationsView()
                        } label: {
                            Image(systemName: "paperplane")
                                .imageScale(.large)
                                .scaledToFit()
                                .foregroundColor(showUnreadMessageBadge ? .red : (colorScheme == .dark ? .white : .black))   // CHANGED
                        }
                        .simultaneousGesture(TapGesture().onEnded {   // NEW — clear on open
                            pushBadgeState.hasUnreadMessages = false
                        })
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
            .task {   // NEW
                    await pushBadgeState.refreshFromFirestore()
                }
            .onChange(of: notiViewModel.hasNewNotifications) {
                print("DEBUG: CurrentUserProfileView - hasNewNotifications: \(notiViewModel.hasNewNotifications)")
            }
            .onChange(of: selectedSettingsOption) {
                guard let option = selectedSettingsOption else { return }
                switch option {
                case .logout:
                    AuthService.shared.signout()
                case .settings, .bookmark, .emptyView:   // CHANGED — bookmark now routes through showDetail too
                    showDetail = true
                }
            }
        } 
    }
    
    @ViewBuilder
    private var content: some View {
        switch selectedFilter {
        case .map:
            EmptyView()   // never actually reached — .map is handled entirely in Mode 1 above
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

struct CurrentUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentUserProfileView(user: User.MOCK_USERS[0])
    }
}
