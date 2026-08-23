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
    
    @StateObject private var deepLinkManager = DeepLinkManager.shared   // NEW
    @State private var presentedDeepLinkUser: DeepLinkUserWrapper?      // NEW
    @State private var presentedDeepLinkPost: DeepLinkPostWrapper?
    
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
            UploadStatusToast()
            DeleteStatusToast()
        }
        .coordinateSpace(name: "onboardingSpace")
        .environmentObject(onboardingManager)
        .environmentObject(markerOnboardingManager)
        .onPreferenceChange(OnboardingTargetKey.self) { onboardingFrames = $0 }
        .onPreferenceChange(MarkerOnboardingTargetKey.self) { markerOnboardingFrames = $0 }
        .onChange(of: onboardingManager.requestedTabIndex) { newValue in
            if let newValue {
                withAnimation { selectedIndex = newValue }
            }
        }
        .onAppear {
            if let initialTab = onboardingManager.requestedTabIndex {
                selectedIndex = initialTab
            }
        }
        .onReceive(deepLinkManager.$pendingDestination) { destination in   // NEW
            guard let destination else { return }
            Task { await handleDeepLink(destination) }
        }
        .fullScreenCover(item: $presentedDeepLinkUser) { wrapper in
            NavigationStack {
                if wrapper.mode == .chat {
                    ChatView(user: wrapper.user)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button { presentedDeepLinkUser = nil } label: {
                                    Image(systemName: "chevron.left").font(.body.weight(.semibold))
                                }
                            }
                        }
                } else {
                    ProfileView(user: wrapper.user, onDismissOverride: { presentedDeepLinkUser = nil })   // CHANGED
                }
            }
        }
        .fullScreenCover(item: $presentedDeepLinkPost) { wrapper in
            NavigationStack {
                Group {
                    if let videoUrl = wrapper.post.videoUrl, !videoUrl.isEmpty {
                        PostGridFeedCell(viewModel: FeedCellViewModel(post: wrapper.post), autoOpenComments: wrapper.openComments)
                    } else {
                        PostGridFeedCellPhoto(viewModel: FeedCellViewModel(post: wrapper.post), autoOpenComments: wrapper.openComments)
                    }
                }
                .toolbar {   // NEW
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            presentedDeepLinkPost = nil
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.white)   // post cells have dark/video backgrounds, keep it visible
                        }
                    }
                }
            }
        }
        .task {   // NEW — seeds the badge once per app session, not per tab switch
                    await PushBadgeState.shared.refreshFromFirestore()
                }
        
    }
    
    @MainActor
    private func handleDeepLink(_ destination: DeepLinkDestination) async {
        defer { deepLinkManager.pendingDestination = nil }
        
        presentedDeepLinkUser = nil
        presentedDeepLinkPost = nil
        
        switch destination {
        case .notifications:
            withAnimation { selectedIndex = 2 }
            
        case .profile(let uid):
            guard let fetchedUser = try? await UserService.fetchUser(withUid: uid) else { return }
            presentedDeepLinkUser = DeepLinkUserWrapper(user: fetchedUser, mode: .profile)
            await markMatchingNotificationViewed { $0.uid == uid && $0.type == .follow }   // NEW
            
        case .chat(let uid):
            guard let fetchedUser = try? await UserService.fetchUser(withUid: uid) else { return }
            presentedDeepLinkUser = DeepLinkUserWrapper(user: fetchedUser, mode: .chat)
            await markMatchingNotificationViewed { $0.uid == uid && $0.type == .message }
            await NotificationService.markAllMessageNotificationsAsViewed()   // CHANGED — awaited, not fire-and-forget
            PushBadgeState.shared.hasUnreadMessages = false   // CHANGED — now set only after the write is actually confirmed done
            
        case .post(let postId, let openComments):
            guard let post = await PostService.fetchPost(withId: postId) else { return }
            presentedDeepLinkPost = DeepLinkPostWrapper(post: post, openComments: openComments)
            await markMatchingNotificationViewed { $0.postId == postId && ($0.type == .like || $0.type == .comment) }   // NEW
        }
    }
    
    // NEW — finds the matching notification(s) in what's already loaded and marks them viewed
    @MainActor
    private func markMatchingNotificationViewed(where predicate: (Notification) -> Bool) async {
        if notiViewModel.notifications.isEmpty {
            await notiViewModel.updateNotifications()
        }
        for notification in notiViewModel.notifications where predicate(notification) && !notification.isViewed {
            notiViewModel.markNotificationAsViewed(notification: notification)
        }
        await notiViewModel.updateNotifications()   // refresh badge/list state
    }
}
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(user: User.MOCK_USERS[1])
    }
}
