//
//  MainTabView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct MainTabView: View {
    let user: User
    @State private var selectedIndex = 0
    @StateObject var locationViewModel = LocationSearchViewModel()
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            FeedView()
                .onAppear {
                    selectedIndex = 0
                }
                .tabItem {
                    Image(systemName: "house")
                }.tag(0)
            
            SearchView()
                .onAppear {
                    selectedIndex = 1
                }
            .tabItem {
                Image(systemName: "magnifyingglass")
            }.tag(1)
            
            UploadPostView(tabIndex: $selectedIndex)
                .onAppear {
                    selectedIndex = 2
                }
            .tabItem {
                Image(systemName: "plus.app")
            }.tag(2)
            
            MapView(user: user)
                .environmentObject(locationViewModel)
                .onAppear {
                    selectedIndex = 3
                }
                .tabItem {
                    Image(systemName: "globe.desk.fill")
                }.tag(3)
            
            CurrentUserProfileView(user: user)
                .onAppear {
                    selectedIndex = 4
                }
            .tabItem {
                Image(systemName: "figure.wave.circle")
            }.tag(4)
        }
        .accentColor(.black)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(user: User.MOCK_USERS[1])
    }
}
