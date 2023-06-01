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
    @State private var selectedFilter: ProfileFilterSelector = .hearts
    @Namespace var animation
    
    init(user: User) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }

        var body: some View {
            ScrollView {
                //header
                ProfileHeaderView(viewModel: viewModel)
                //profile filter bar
                ProfileFilterView()
                // post grid view
                brocheView
            //    PostGridView(config: .profile(user))
            }
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
    }
    
    
    
    var profileFilterBar: some View {
        
        HStack {
            ForEach(ProfileFilterSelector.allCases, id: \.rawValue) { item in
                VStack {
                    Image(systemName: item.imageName)
                        .font(.subheadline)
                        .imageScale(.large)
                        .fontWeight(selectedFilter == item ? .semibold : .regular)
                        .foregroundColor(selectedFilter == item ? .black : . gray)
                    
                    if selectedFilter == item {
                        Capsule()
                            .foregroundColor(.black)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "filter", in: animation)
                    } else {
                        Capsule()
                            .foregroundColor(.clear)
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        self.selectedFilter = item
                    }
                }
            }
        }
        .overlay(Divider().offset(x: 0, y: 16))
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
                     PostGridView(config: .profile(user))
                    //  MapView2()
                }
                
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(user: User.MOCK_USERS[0])
    }
}
