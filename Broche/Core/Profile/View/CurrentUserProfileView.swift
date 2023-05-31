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
                ProfileFilterView()
                // post grid view
                PostGridView(config: .profile(user))
            }
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showDetail, destination: {
                Text(selectedSettingsOption?.title ?? "")
            })
            .sheet(isPresented: $showSettingsSheet) {
                SettingsView(selectedOption: $selectedSettingsOption)
                    .presentationDetents([.height(CGFloat(SettingsItemModel.allCases.count * 56))])
            }
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedSettingsOption = nil
                        showSettingsSheet.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            })
            .onChange(of: selectedSettingsOption) { newValue in
                guard let option = newValue else { return }
                
                if option != .logout {
                    self.showDetail.toggle()
                } else  {
                    AuthService.shared.signout()
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
