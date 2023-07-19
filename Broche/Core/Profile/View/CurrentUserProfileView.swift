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
    @State private var showSettingsSheet = false
    @State private var selectedSettingsOption: SettingsItemModel?
    @State private var showDetail = false
    @State private var selectedFilter: ProfileFilterSelector = .hearts
    @Environment(\.colorScheme) var colorScheme
    
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
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
            .navigationDestination(isPresented: $showDetail) {
                if let option = selectedSettingsOption {
                    switch option {
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
                                NotificationsView()
                            } label: {
                                Image(systemName: "bell")
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
