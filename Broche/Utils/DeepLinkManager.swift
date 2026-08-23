//
//  DeepLinkManager.swift
//  Broche
//
//  Created by Jacob Johnson on 8/22/26.
//

import SwiftUI

enum DeepLinkDestination {
    case profile(uid: String)
    case chat(uid: String)
    case post(postId: String, openComments: Bool)   // NEW
    case notifications
}

@MainActor
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    @Published var pendingDestination: DeepLinkDestination?
}

struct DeepLinkUserWrapper: Identifiable {
    enum Mode { case profile, chat }
    let id = UUID()
    let user: User
    let mode: Mode
}

struct DeepLinkPostWrapper: Identifiable {
    let id = UUID()
    let post: Post
    let openComments: Bool
}
