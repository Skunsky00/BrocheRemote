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
    @StateObject var notiViewModel = NotificationsViewModel()
    @StateObject var onboardingManager = OnboardingManager()   // NEW
    @State private var onboardingFrames: [OnboardingStep: CGRect] = [:]   // NEW
    @StateObject var markerOnboardingManager = MarkerOnboardingManager()
    @State private var markerOnboardingFrames: [MarkerOnboardingStep: CGRect] = [:]
    @Environment(\.colorScheme) var colorScheme
    
    var accentColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        ZStack{
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
                
                NotificationsView(viewModel: notiViewModel)
                    .onAppear {
                        selectedIndex = 2
                    }
                    .tabItem {
                        Image(systemName: "bell")
                    }
                    .badge(notiViewModel.hasNewNotifications ? "" : nil)
                    .tag(2)
                
                CurrentUserProfileView(user: user)
                    .onAppear {
                        selectedIndex = 3
                    }
                    .tabItem {
                        Image(systemName: "figure.wave.circle")
                    }.tag(3)
            }
            .accentColor(accentColor)
            .environment(\.horizontalSizeClass, .compact) 
            
            OnboardingOverlay(manager: onboardingManager, frames: onboardingFrames)
            MarkerOnboardingOverlay(manager: markerOnboardingManager, frames: markerOnboardingFrames)   // ADD THIS
        }
        .coordinateSpace(name: "onboardingSpace")   // NEW
        .environmentObject(onboardingManager)   // NEW — so MapView2/ProfileView can advance steps
        .environmentObject(markerOnboardingManager)
        .onPreferenceChange(OnboardingTargetKey.self) { onboardingFrames = $0 }   // NEW
        .onPreferenceChange(MarkerOnboardingTargetKey.self) { markerOnboardingFrames = $0 }
        .onChange(of: onboardingManager.requestedTabIndex) { newValue in   // NEW
                    if let newValue {
                        withAnimation {
                            selectedIndex = newValue
                        }
                    }
                }
                .onAppear {   // NEW — handle the very first step too, on initial launch
                    if let initialTab = onboardingManager.requestedTabIndex {
                        selectedIndex = initialTab
                    }
                }
    }
}
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(user: User.MOCK_USERS[1])
    }
}
