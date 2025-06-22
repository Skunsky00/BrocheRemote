//
//  BookmarkSheet.swift
//  Broche
//
//  Created by Jacob Johnson on 6/21/25.
//

import SwiftUI

struct BookmarkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CollectionsViewModel
    let onSelectCollection: (Collection) -> Void
    let onCreateCollection: (String) -> Void
    
    init(userId: String, onSelectCollection: @escaping (Collection) -> Void, onCreateCollection: @escaping (String) -> Void) {
        self._viewModel = StateObject(wrappedValue: CollectionsViewModel(userId: userId))
        self.onSelectCollection = onSelectCollection
        self.onCreateCollection = onCreateCollection
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Save to Collection")
                .font(.headline)
                .padding(.top, 16)
            
            if viewModel.state.isLoading {
                ProgressView()
                    .padding()
            } else if let error = viewModel.state.error {
                VStack {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        viewModel.fetchCollections()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            } else if viewModel.state.collections.isEmpty {
                Text("No collections yet. Create one below!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.state.collections) { collection in
                            Button(action: {
                                onSelectCollection(collection)
                                dismiss()
                            }) {
                                Text(collection.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .accessibilityLabel("Select collection: \(collection.name)")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            VStack(spacing: 8) {
                TextField("New Collection Name", text: $viewModel.newCollectionName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button(action: {
                    if !viewModel.newCollectionName.isEmpty {
                        onCreateCollection(viewModel.newCollectionName)
                        viewModel.newCollectionName = ""
                        dismiss()
                    }
                }) {
                    Text("Create")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.newCollectionName.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)
                .disabled(viewModel.newCollectionName.isEmpty)
                .accessibilityLabel("Create new collection")
            }
            .padding(.bottom)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            print("BookmarkSheet appeared, fetching collections for userId: \(viewModel.userId ?? "nil")")
            viewModel.fetchCollections()
        }
    }
}

