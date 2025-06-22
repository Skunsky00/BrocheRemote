//
//  CollectionsViewodel.swift
//  Broche
//
//  Created by Jacob Johnson on 6/14/25.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore

class CollectionsViewModel: ObservableObject {
    @Published var state = CollectionsState()
    @Published var newCollectionName: String = ""
    let userId: String?
    private var listener: ListenerRegistration?
    
    init(userId: String? = nil) {
        self.userId = userId
        fetchCollections()
    }
    
    deinit {
        listener?.remove()
    }
    
    func fetchCollections() {
        guard let fetchUserId = userId ?? Auth.auth().currentUser?.uid else {
            print("No authenticated user or userId provided")
            state = CollectionsState(error: "No user logged in")
            return
        }
        
        state = CollectionsState(isLoading: true)
        
        listener?.remove()
        listener = Firestore.firestore().collection("users")
            .document(fetchUserId)
            .collection("collections")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching collections for user \(fetchUserId): \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.state = CollectionsState(error: error.localizedDescription)
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found for user \(fetchUserId)")
                    DispatchQueue.main.async {
                        self.state = CollectionsState(collections: [], error: "No collections found")
                    }
                    return
                }
                
                let collections = documents.compactMap { doc -> Collection? in
                    do {
                        var collection = try doc.data(as: Collection.self)
                        if collection.id == nil {
                            collection.id = doc.documentID
                        }
                        print("Decoded collection: id=\(collection.id ?? "nil"), name=\(collection.name), createdAt=\(ISO8601DateFormatter().string(from: collection.createdAt)), thumbnailUrl=\(collection.thumbnailUrl ?? "nil")")
                        return collection
                    } catch {
                        print("Error decoding collection \(doc.documentID): \(error)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    print("Fetched \(collections.count) valid collections")
                    self.state = CollectionsState(collections: collections)
                }
            }
    }
    
    func createCollection(name: String) {
        guard let authUid = Auth.auth().currentUser?.uid else {
            print("Cannot create collection: No authenticated user")
            state = state.copy(error: "No user logged in")
            return
        }
        
        Task {
            do {
                let newCollection = try await PostService.createCollection(userId: authUid, name: name)
                if newCollection?.id != nil, !newCollection!.name.isEmpty {
                    print("Created collection: \(name)")
                } else {
                    await MainActor.run {
                        print("Invalid collection created")
                        self.state = self.state.copy(error: "Invalid collection created")
                    }
                }
            } catch {
                await MainActor.run {
                    print("Error creating collection: \(error.localizedDescription)")
                    self.state = self.state.copy(error: error.localizedDescription)
                }
            }
        }
    }
    
    func addPostToCollection(collectionId: String, postId: String) {
        guard let authUid = Auth.auth().currentUser?.uid else {
            print("Cannot add post: No authenticated user")
            state = state.copy(error: "No user logged in")
            return
        }
        
        Task {
            do {
                try await PostService.addPostToCollection(userId: authUid, collectionId: collectionId, postId: postId)
                print("Added post \(postId) to collection \(collectionId)")
            } catch {
                await MainActor.run {
                    print("Error adding post to collection: \(error.localizedDescription)")
                    self.state = self.state.copy(error: error.localizedDescription)
                }
            }
        }
    }
    
    func removePostFromAllCollections(postId: String) {
        guard let authUid = Auth.auth().currentUser?.uid else {
            print("Cannot remove post: No authenticated user")
            state = state.copy(error: "No user logged in")
            return
        }
        
        Task {
            do {
                try await PostService.removePostFromAllCollections(userId: authUid, postId: postId)
                print("Removed post \(postId) from all collections")
            } catch {
                await MainActor.run {
                    print("Error removing post from collections: \(error.localizedDescription)")
                    self.state = self.state.copy(error: error.localizedDescription)
                }
            }
        }
    }
    
    func isPostInAnyCollection(postId: String) async -> Bool {
        guard let authUid = Auth.auth().currentUser?.uid else {
            print("Cannot check collections: No authenticated user")
            return false
        }
        
        do {
            return try await PostService.isPostInAnyCollection(userId: authUid, postId: postId)
        } catch {
            print("Error checking collections: \(error.localizedDescription)")
            return false
        }
    }
    
    func showCreateCollectionDialog() {
        state = state.copy(showCreateDialog: true)
    }
    
    func hideCreateCollectionDialog() {
        state = state.copy(showCreateDialog: false)
    }
}

struct CollectionsState {
    var collections: [Collection] = []
    var isLoading: Bool = false
    var error: String? = nil
    var showCreateDialog: Bool = false
    
    func copy(
        collections: [Collection]? = nil,
        isLoading: Bool? = nil,
        error: String?? = nil,
        showCreateDialog: Bool? = nil
    ) -> CollectionsState {
        CollectionsState(
            collections: collections ?? self.collections,
            isLoading: isLoading ?? self.isLoading,
            error: error ?? self.error,
            showCreateDialog: showCreateDialog ?? self.showCreateDialog
        )
    }
}
