//
//  SearchViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/22/23.
//

import SwiftUI
import Firebase

enum SearchViewModelConfig: Hashable {
    case followers(String)
    case following(String)
//    case followingLocation(String)
    case likes(String)
    case search
    case newMessage
    
    var navigationTitle: String {
        switch self {
        case .followers:
            return "Followers"
        case .following:
            return "Following"
//        case .followingLocation:
//            return "FollowingLocation"
        case .likes:
            return "Likes"
        case .search:
            return "Explore"
        case .newMessage:
            return "NewMessage"
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var users = [User]()
    private let config: SearchViewModelConfig
    private var lastDoc: QueryDocumentSnapshot?
    private var searchQuery: String?
    
    init(config: SearchViewModelConfig) {
        self.config = config
        fetchUsers(forConfig: config)
    }
    
    
    func fetchUsers() async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let query = COLLECTION_USERS

        if let last = lastDoc {
            let next = query.start(afterDocument: last)
            guard let snapshot = try? await next.getDocuments() else { return }
            self.lastDoc = snapshot.documents.last
            self.users.append(contentsOf: snapshot.documents.compactMap({ try? $0.data(as: User.self) }))
        } else {
            guard let snapshot = try? await query.getDocuments() else { return }
            self.lastDoc = snapshot.documents.last
            self.users = snapshot.documents.compactMap({ try? $0.data(as: User.self) }).filter({ $0.id != currentUid })
        }
    }


    
    func fetchUsers(forConfig config: SearchViewModelConfig) {
        Task {
            switch config {
            case .followers(let uid):
                try await fetchFollowerUsers(forUid: uid)
            case .following(let uid):
                try await fetchFollowingUsers(forUid: uid)
//            case .followingLocation(let uid):
//                        try await fetchFollowingLocationUsers(forUid: uid, location: )
             case .likes(let postId):
                try await fetchPostLikesUsers(forPostId: postId)
            case .search, .newMessage:
                print("DEBUG: Fetching users..")
                 await fetchUsers()
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
    
    private func fetchFollowingLocationUsers(forUid uid: String, location: Location) async throws {
        guard let snapshot = try? await COLLECTION_FOLLOWING.document(uid).collection("user-following").getDocuments() else { return }
        try await fetchUsersWithLocation(snapshot, location: location)
    }


    
    private func fetchUsers(_ snapshot: QuerySnapshot?) async throws {
        guard let documents = snapshot?.documents else { return }
        
        for doc in documents {
            let user = try await UserService.fetchUser(withUid: doc.documentID)
            users.append(user)
        }
    }
    
    private func fetchUsersWithLocation(_ snapshot: QuerySnapshot?, location: Location) async throws {
        guard let documents = snapshot?.documents else { return }

        for doc in documents {
            let friend = try await UserService.fetchUser(withUid: doc.documentID)

            // Check if the friend has a location and it matches the desired location
            if let friendLocation = friend.location,
               friendLocation.latitude == location.latitude,
               friendLocation.longitude == location.longitude {
                users.append(friend)
            }
        }
    }

    // Update the search query when the user types in the search bar
    func updateSearchQuery(_ query: String) {
        // Reset the list of users before fetching new ones.
        users.removeAll()
        searchQuery = query
        fetchUsers(forConfig: config)
    }

    
    func filteredUsers(_ query: String) -> [User] {
        
        let lowercasedQuery = query.lowercased()
        return users.filter({
            $0.fullname?.lowercased().contains(lowercasedQuery) ?? false ||
            $0.username.contains(lowercasedQuery)
        })
    }
    
    func clearUsers() {
        users.removeAll()
    }
}
