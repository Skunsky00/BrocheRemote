//
//  BrocheApp.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging


class AppDelegate: NSObject, UIApplicationDelegate {
    
    let gcmMessageIDKey = "gcm.Message_ID"
    
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      
  //    UNUserNotificationCenter.current().delegate = self
//      
//      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//      UNUserNotificationCenter.current().requestAuthorization(
//        options: authOptions,
//        completionHandler: { _, _ in }
//      )
//
//      application.registerForRemoteNotifications()
      
    //  Messaging.messaging().delegate = self
      
      
      
    return true
  }
    
    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//            Messaging.messaging().apnsToken = deviceToken
//        }
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
                    .clipShape(RoundedRectangle(cornerRadius: 40)) // Dynamic rounded corners
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


//extension AppDelegate: UNUserNotificationCenterDelegate {
//    // Receive displayed notifications for iOS 10 devices.
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                willPresent notification: UNNotification) async
//      -> UNNotificationPresentationOptions {
//      let userInfo = notification.request.content.userInfo
//
//      // With swizzling disabled you must let Messaging know about the message, for Analytics
//      // Messaging.messaging().appDidReceiveMessage(userInfo)
//
//      // ...
//
//      // Print full message.
//      print(userInfo)
//
//      // Change this to your preferred presentation option
//          return [[.sound]]
//    }
//
//    func userNotificationCenter(_ center: UNUserNotificationCenter,
//                                didReceive response: UNNotificationResponse) async {
//      let userInfo = response.notification.request.content.userInfo
//
//      // ...
//
//      // With swizzling disabled you must let Messaging know about the message, for Analytics
//      // Messaging.messaging().appDidReceiveMessage(userInfo)
//
//      // Print full message.
//      print(userInfo)
//    }
//    
//    
//    // Silent notifications
//    func application(_ application: UIApplication,
//                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
//      -> UIBackgroundFetchResult {
//      // If you are receiving a notification message while your app is in the background,
//      // this callback will not be fired till the user taps on the notification launching the application.
//      // TODO: Handle data of notification
//
//      // With swizzling disabled you must let Messaging know about the message, for Analytics
//      // Messaging.messaging().appDidReceiveMessage(userInfo)
//
//      // Print message ID.
//      if let messageID = userInfo[gcmMessageIDKey] {
//        print("Message ID: \(messageID)")
//      }
//
//      // Print full message.
//      print(userInfo)
//
//      return UIBackgroundFetchResult.newData
//    }
//  }
//
//extension AppDelegate: MessagingDelegate {
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//      print("Firebase registration token: \(String(describing: fcmToken))")
//
//      let dataDict: [String: String] = ["token": fcmToken ?? ""]
//        Foundation.NotificationCenter.default.post(
//        name: Foundation.Notification.Name("FCMToken"),
//        object: nil,
//        userInfo: dataDict
//      )
//      // TODO: If necessary send token to application server.
//      // Note: This callback is fired at each app startup and whenever a new token is generated.
//    }
//}
