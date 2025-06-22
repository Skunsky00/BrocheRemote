//
//  CollectionsView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/14/25.
//

import SwiftUI
import FirebaseAuth

struct CollectionsView: View {
    @StateObject private var viewModel: CollectionsViewModel
    let user: User
    let disableScrolling: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(user: User, disableScrolling: Bool = false) {
        self.user = user
        self.disableScrolling = disableScrolling
        self._viewModel = StateObject(wrappedValue: CollectionsViewModel(userId: user.id))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                collectionsContentView
                if viewModel.state.showCreateDialog {
                    CreateCollectionDialog(
                        onDismiss: { viewModel.hideCreateCollectionDialog() },
                        onCreate: { name in
                            viewModel.createCollection(name: name)
                            viewModel.hideCreateCollectionDialog()
                        }
                    )
                    .zIndex(1)
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                if user.isCurrentUser {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { viewModel.showCreateCollectionDialog() }) {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Create new collection")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var collectionsContentView: some View {
        if viewModel.state.isLoading {
            collectionsGridSkeletonView
        } else if let error = viewModel.state.error {
            errorView(error)
        } else if viewModel.state.collections.isEmpty {
            emptyView
        } else {
            collectionsGridView
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        VStack {
            Text("No collections yet. Create one below!")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            if user.isCurrentUser {
                createCollectionButtonView
            }
        }
    }
    
    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        VStack {
            Text("Error: \(error)")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
                .padding()
            Button("Retry") {
                viewModel.fetchCollections()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .accessibilityLabel("Retry fetching collections")
        }
    }
    
    @ViewBuilder
    private var createCollectionButtonView: some View {
        Button(action: { viewModel.showCreateCollectionDialog() }) {
            HStack {
                Image(systemName: "plus")
                Text("Create Collection")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel("Create new collection")
    }
    
    @ViewBuilder
    private var createCollectionCardView: some View {
        ZStack {
            Color(.systemGray6)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 2)
            Button(action: { viewModel.showCreateCollectionDialog() }) {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.primary)
            }
        }
        .aspectRatio(1, contentMode: ContentMode.fit)
        .accessibilityLabel("Create new collection")
    }
    
    @ViewBuilder
    private var collectionsGridView: some View {
        let content = VStack(spacing: 8) {
            if user.isCurrentUser {
                createCollectionCardView
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(viewModel.state.collections) { collection in
                    NavigationLink(
                        destination: PostGridView(config: .collectionPosts(userId: user.id, collectionId: collection.id!))
                            .navigationTitle("Collection Posts")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: { dismiss() }) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.primary)
                                    }
                                    .accessibilityLabel("Back to Collections")
                                }
                            }
                    ) {
                        ZStack {
                            if let thumbnailUrl = collection.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color(.systemGray6)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 2)
                            } else {
                                Color(.systemGray6)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .shadow(radius: 2)
                            }
                            
                            Text(collection.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .multilineTextAlignment(.center)
                                .padding(8)
                        }
                        .aspectRatio(1, contentMode: ContentMode.fit)
                        .contextMenu {
                            if user.isCurrentUser {
                                Button(role: .destructive) {
                                    viewModel.deleteCollection(collectionId: collection.id!)
                                } label: {
                                    Label("Delete Collection", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .accessibilityLabel("Collection: \(collection.name)")
                }
            }
        }
        
        if disableScrolling {
            content
                .padding(16)
        } else {
            ScrollView {
                content
                    .padding(16)
            }
        }
    }
    
    @ViewBuilder
    private var collectionsGridSkeletonView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(0..<4, id: \.self) { _ in
                Rectangle()
                    .fill(Color(.systemGray6))
                    .aspectRatio(1, contentMode: ContentMode.fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .padding(16)
    }
}

struct CreateCollectionDialog: View {
    @State private var collectionName: String = ""
    let onDismiss: () -> Void
    let onCreate: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Create New Collection")
                .font(.headline)
                .padding(.top, 16)
            
            TextField("Collection Name", text: $collectionName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button(action: onDismiss) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: {
                    if !collectionName.isEmpty {
                        onCreate(collectionName)
                    }
                }) {
                    Text("Create")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(collectionName.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(collectionName.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .padding(.horizontal, 32)
    }
}
