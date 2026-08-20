//
//  SearchViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/22/23.
//

import SwiftUI
import Firebase
import CoreLocation

enum SearchViewModelConfig: Hashable {
    case followers(String)
    case following(String)
    case likes(String)
    case search
    case newMessage
    case sharepost(String) // Pass UID for context
    case friendsWhoVisited(lat: Double, lon: Double)   // NEW

    var navigationTitle: String {
        switch self {
        case .followers:
            return "Followers"
        case .following:
            return "Following"
        case .likes:
            return "Likes"
        case .search:
            return "Explore"
        case .newMessage:
            return "New Message"
        case .sharepost:
            return "Send Post"
        case .friendsWhoVisited:
            return "Been Here"
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var users = [User]()          // paginated browse list
    @Published var searchResults = [User]()  // NEW — separate list, only populated during search
    private let config: SearchViewModelConfig
    private var lastDoc: QueryDocumentSnapshot?
    private let pageSize = 20
    private var isFetching = false
    private var hasMorePages = true
    
    var supportsPagination: Bool {   // NEW
        switch config {
        case .search, .newMessage:
            return true
        default:
            return false
        }
    }

    init(config: SearchViewModelConfig) {
        self.config = config
        fetchUsers(forConfig: config)
    }

    func fetchUsers() async {
        guard !isFetching, hasMorePages else { return }
        isFetching = true
        defer { isFetching = false }

        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let query = COLLECTION_USERS
            .order(by: "username")
            .limit(to: pageSize)

        if let last = lastDoc {
            let next = query.start(afterDocument: last)
            guard let snapshot = try? await next.getDocuments() else { return }
            if snapshot.documents.count < pageSize { hasMorePages = false }
            self.lastDoc = snapshot.documents.last
            self.users.append(contentsOf: snapshot.documents.compactMap({ try? $0.data(as: User.self) }))
        } else {
            guard let snapshot = try? await query.getDocuments() else { return }
            if snapshot.documents.count < pageSize { hasMorePages = false }
            self.lastDoc = snapshot.documents.last
            self.users = snapshot.documents.compactMap({ try? $0.data(as: User.self) }).filter({ $0.id != currentUid })
        }
    }

    // NEW — server-side search, independent of pagination state
    func search(_ queryText: String) async {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }

        guard let snapshot = try? await COLLECTION_USERS
            .order(by: "username")
            .start(at: [trimmed])
            .end(at: [trimmed + "\u{f8ff}"])
            .limit(to: 20)
            .getDocuments() else { return }

        searchResults = snapshot.documents
            .compactMap { try? $0.data(as: User.self) }
            .filter { $0.id != currentUid }
    }

    func fetchUsers(forConfig config: SearchViewModelConfig) {
        Task {
            switch config {
            case .followers(let uid):
                try await fetchFollowerUsers(forUid: uid)
            case .following(let uid):
                try await fetchFollowingUsers(forUid: uid)
            case .likes(let postId):
                try await fetchPostLikesUsers(forPostId: postId)
            case .search, .newMessage:
                await fetchUsers()
            case .sharepost(let uid):
                try await fetchFollowingUsers(forUid: uid)
            case .friendsWhoVisited(let lat, let lon):   // NEW
                       let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                       let matched = await UserService.fetchFriendsWhoVisited(coordinate: coordinate)
                       await MainActor.run { self.users = matched }
            }
        }
    }

    private func fetchPostLikesUsers(forPostId postId: String) async throws {
        guard let snapshot = try? await COLLECTION_POSTS.document(postId).collection("post-likes").getDocuments() else { return }
        try await fetchUsers(snapshot)
    }

    private func fetchFollowerUsers(forUid uid: String) async throws {
        guard let snapshot = try? await COLLECTION_FOLLOWERS.document(uid).collection("user-followers").getDocuments() else { return }
        try await fetchUsers(snapshot)
    }

    private func fetchFollowingUsers(forUid uid: String) async throws {
        guard let snapshot = try? await COLLECTION_FOLLOWING.document(uid).collection("user-following").getDocuments() else { return }
        try await fetchUsers(snapshot)
    }

    private func fetchUsers(_ snapshot: QuerySnapshot?) async throws {
        guard let documents = snapshot?.documents else { return }

        for doc in documents {
            let user = try await UserService.fetchUser(withUid: doc.documentID)
            users.append(user)
        }
    }

//    func updateSearchQuery(_ query: String) {
//        users.removeAll()
//        searchQuery = query
//        fetchUsers(forConfig: config)
//    }
//
//    func filteredUsers(_ query: String) -> [User] {
//        let lowercasedQuery = query.lowercased()
//        return users.filter {
//            $0.fullname?.lowercased().contains(lowercasedQuery) ?? false || $0.username.contains(lowercasedQuery)
//        }
//    }

    func clearUsers() {
        users.removeAll()
    }
}
