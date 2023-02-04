//
//  MainTab.swift
//  Broche
//
//  Created by Jacob Johnson on 12/10/22.
//

import SwiftUI

struct MainTabView: View {
    let user: User
    @State private var selectedIndex = 0
    @StateObject var locationViewModel = LocationSearchViewModel()
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedIndex) {
                FeedView()
                    .onTapGesture {
                        self.selectedIndex = 0
                    }
                    .tabItem {
                        Image(systemName: "house")
                    }.tag(0)
                
                ExploreView()
                    .onTapGesture {
                        self.selectedIndex = 1
                    }
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                    }.tag(1)
                
                PhotoPickerView()
                    .onTapGesture {
                        self.selectedIndex = 2
                    }
                    .tabItem {
                        Image(systemName: "plus.app")
                    }.tag(2)
                
                MapView2()
                    .environmentObject(locationViewModel)
                    .onTapGesture {
                        self.selectedIndex = 3
                    }
                    .tabItem {
                        Image(systemName: "globe.desk.fill")
                    }.tag(3)
                
                ProfileView2(user: user)
                    .onTapGesture {
                        self.selectedIndex = 4
                    }
                    .tabItem {
                        Image(systemName: "figure.wave.circle")
                    }.tag(4)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: logoutButton)
            .accentColor(.black)
        }
    }
    
    var logoutButton: some View {
        Button(action: {
            AuthViewModel.shared.signout()
        }, label: {
            Text("Logout").foregroundColor(.black)
        })
    }
}

