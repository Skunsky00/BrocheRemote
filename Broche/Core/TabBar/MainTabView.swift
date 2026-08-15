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
    @StateObject var locationViewModel = LocationSearchViewModel2()
    @Environment(\.colorScheme) var colorScheme
    
    var accentColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            MapView2(user: user)
                .environmentObject(locationViewModel)
                .onAppear {
                    selectedIndex = 0
                }
                .tabItem {
                    Image(systemName: "globe.desk.fill")
                }.tag(0)
            
            SearchView()
                .onAppear {
                    selectedIndex = 1
                }
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }.tag(1)
            
            // Tab 2 open — activity/notifications, or just drop to 4 tabs
            
            FeedView()
                .onAppear {
                    selectedIndex = 2
                }
                .tabItem {
                    Image(systemName: "house")
                }.tag(2)
            
            CurrentUserProfileView(user: user)
                .onAppear {
                    selectedIndex = 3
                }
                .tabItem {
                    Image(systemName: "figure.wave.circle")
                }.tag(3)
        }
        .accentColor(accentColor)
    }
}
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(user: User.MOCK_USERS[1])
    }
}
