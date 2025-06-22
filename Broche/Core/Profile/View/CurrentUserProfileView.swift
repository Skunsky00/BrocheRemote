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
    @State private var selectedFilter: ProfileFilterSelector = .broche
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
            ScrollView {
                // Header
                ProfileHeaderView(viewModel: viewModel)
                // Profile filter bar
                ProfileFilterView(selectedFilter: $selectedFilter)
                // Content based on filter
                brocheView
            }
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(brocheViewModel)
            .refreshable {
                viewModel.updateUserData(user: user)
            }
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
        }
    }
    
    var brocheView: some View {
        ScrollView {
            LazyVStack {
                switch selectedFilter {
                case .broche:
                    BrocheGridView(user: user)
                case .hearts:
                    PostGridView(config: .likedPosts(user))
                case .bookmarks:
                    CollectionsView(user: user, disableScrolling: true)
                case .mappin:
                    MapViewForUserPins(user: user)
                }
            }
        }
    }
}

struct CurrentUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentUserProfileView(user: User.MOCK_USERS[0])
    }
}
