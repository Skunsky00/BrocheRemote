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
    @State private var selectedFilter: ProfileFilterSelector = .hearts
    @Environment(\.colorScheme) var colorScheme
    
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self._notiViewModel = StateObject(wrappedValue: NotificationsViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                //header
                ProfileHeaderView(viewModel: viewModel)
                //profile filter bar
                ProfileFilterView(selectedFilter: $selectedFilter)
                // post grid view
                brocheView
            }
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.loadUserData()
            }
            .navigationDestination(isPresented: $showDetail) {
                if let option = selectedSettingsOption {
                    switch option {
                    case .settings:
                            NavigationView {
                                SettingsAndPrivacyView(user: user, selectedOption: $selectedSettingsPrivacy)
                                    .navigationTitle("Settings") // Add a title for SettingsAndPrivacyView
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
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        NotificationsView(viewModel: notiViewModel) // Pass the ViewModel to NotificationsView
                    } label: {
                        if notiViewModel.hasNewNotifications {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.red)
                            // Bell icon with a red dot
                        } else {
                            Image(systemName: "bell") // Normal bell icon
                        }
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
            })
            .onChange(of: notiViewModel.hasNewNotifications) { newValue in
                // Print statement to check hasNewNotifications in the CurrentUserProfileView
                print("DEBUG: CurrentUserProfileView - hasNewNotifications: \(newValue)")
            }
            .onChange(of: selectedSettingsOption) { newValue in
                guard let option = newValue else { return }
                
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
                switch self.selectedFilter {
                case .hearts:
                    PostGridView(config: .likedPosts(user))
                case .bookmarks:
                    PostGridView(config: .bookmarkedPosts(user))
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
