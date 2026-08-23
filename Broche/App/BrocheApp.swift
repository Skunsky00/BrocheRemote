//
//  BrocheApp.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging


import Firebase
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }

        return true
    }

    // Required so FCM can pair the APNs token with an FCM token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Fires whenever the FCM token is created/refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid)
            .updateData(["fcmToken": fcmToken])
    }

    // Show the banner even while the app is open
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        guard let typeString = userInfo["type"] as? String else {
            completionHandler()
            return
        }

        switch typeString {
        case "0", "1":   // like, comment
            if let postId = userInfo["postId"] as? String {
                DeepLinkManager.shared.pendingDestination = .post(postId: postId, openComments: typeString == "1")
            } else {
                DeepLinkManager.shared.pendingDestination = .notifications
            }
        case "2":   // follow
            if let actorUid = userInfo["actorUid"] as? String {
                DeepLinkManager.shared.pendingDestination = .profile(uid: actorUid)
            }
        case "3":   // message
            if let actorUid = userInfo["actorUid"] as? String {
                DeepLinkManager.shared.pendingDestination = .chat(uid: actorUid)
            }
        default:
            DeepLinkManager.shared.pendingDestination = .notifications
        }

        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let typeString = userInfo["type"] as? String, typeString == "3" {   // NEW — message
            PushBadgeState.shared.hasUnreadMessages = true
        }
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct BrocheApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var viewModel = ContentViewModel()

    var body: some Scene {
        WindowGroup {
            AppWithSplash(viewModel: viewModel)
        }
    }
}

struct AppWithSplash: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var isMinTimePassed = false
    @State private var isInitialNavigationDone = false

    var body: some View {
        ZStack {
            // Main content (loads in background)
            ContentView(viewModel: viewModel)
                .onAppear {
                    // Signal navigation is complete once ContentView is ready
                    isInitialNavigationDone = true
                }

            // Splash screen overlay
            if !(isMinTimePassed && isInitialNavigationDone) {
                SplashView()
            }
        }
        .onAppear {
            // Timer for minimum splash duration (3 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                isMinTimePassed = true
            }
        }
    }
}

struct SplashView: View {
    @State private var alpha: CGFloat = 0.0

    var body: some View {
        let backgroundColor = UITraitCollection.current.userInterfaceStyle == .dark ? Color.black : Color.white

        ZStack {
            backgroundColor
                .ignoresSafeArea()

            if let image = UIImage(named: "appsplash") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 60)) // Dynamic rounded corners
                    .opacity(alpha)
            } else {
                Text("Error loading logo")
                    .foregroundColor(UITraitCollection.current.userInterfaceStyle == .dark ? .white : .black)
            }
        }
        .onAppear {
            // Start 1-second fade-in animation
            withAnimation(.easeIn(duration: 1.0)) {
                alpha = 1.0
            }
        }
    }
}


