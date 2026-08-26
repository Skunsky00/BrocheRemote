//
//  NotificationsSettingsView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/25/26.
//

import SwiftUI

// NEW
struct NotificationsSettingsView: View {
    let user: User
    @State private var likesEnabled = true
    @State private var commentsEnabled = true
    @State private var followsEnabled = true
    @State private var messagesEnabled = true
    @State private var pinsEnabled = true
    @State private var isLoading = true
    
    var body: some View {
        Form {
            if isLoading {
                ProgressView()
            } else {
                Section("Activity") {
                    Toggle("Likes", isOn: $likesEnabled)
                    Toggle("Comments", isOn: $commentsEnabled)
                    Toggle("New Followers", isOn: $followsEnabled)
                    Toggle("New Pins from Friends", isOn: $pinsEnabled)
                }
                Section("Messages") {
                    Toggle("Messages", isOn: $messagesEnabled)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onChange(of: likesEnabled) { _ in save() }
        .onChange(of: commentsEnabled) { _ in save() }
        .onChange(of: followsEnabled) { _ in save() }
        .onChange(of: messagesEnabled) { _ in save() }
        .onChange(of: pinsEnabled) { _ in save() }
    }
    
    private func load() async {
        if let snapshot = try? await COLLECTION_USERS.document(user.id).getDocument(),
           let prefs = snapshot.data()?["notificationPrefs"] as? [String: Bool] {
            likesEnabled = prefs["like"] ?? true
            commentsEnabled = prefs["comment"] ?? true
            followsEnabled = prefs["follow"] ?? true
            messagesEnabled = prefs["message"] ?? true
            pinsEnabled = prefs["newPin"] ?? true
        }
        isLoading = false
    }
    
    private func save() {
        Task {
            try? await COLLECTION_USERS.document(user.id).updateData([
                "notificationPrefs": [
                    "like": likesEnabled,
                    "comment": commentsEnabled,
                    "follow": followsEnabled,
                    "message": messagesEnabled,
                    "newPin": pinsEnabled
                ]
            ])
        }
    }
}
