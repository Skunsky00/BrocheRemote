//
//  EditMarkerView2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI

// Consolidated EditMarkerView2
struct EditMarkerView2: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: EditMarkerViewModel2
    @State private var isSaving = false
    var onSave: (Location) -> Void = { _ in }
    
    init(user: User, location: Location, type: MarkerType, onSave: @escaping (Location) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: EditMarkerViewModel2(user: user, location: location, type: type))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Caption")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("Add details about this place...", text: $viewModel.description, axis: .vertical)
                        .lineLimit(4...8)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                }
                
                if viewModel.type == .visited {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Link")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            TextField("Add a link", text: $viewModel.link)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            
                            if !viewModel.link.isEmpty {
                                Button {
                                    viewModel.link = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Edit Pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") { dismiss() }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                Task {
                                    isSaving = true
                                    if let updated = try? await viewModel.updateUserData() {
                                        onSave(updated)   // NEW
                                    }
                                    isSaving = false
                                    dismiss()
                                }
                            } label: {
                                if isSaving {
                                    ProgressView()
                                } else {
                                    Text("Done").fontWeight(.bold)
                                }
                            }
                            .disabled(isSaving)
                        }
                }
            }
        }
    }
    
    struct EditMarkerRowView2: View {
        let title: String
        let placeholder: String
        @Binding var text: String
        
        var body: some View {
            HStack {
                Text(title)
                    .padding(.leading, 8)
                    .frame(width: 100, alignment: .leading)
                VStack {
                    TextField(placeholder, text: $text, axis: .vertical)
                    Divider()
                }
            }
            .font(.subheadline)
            .frame(height: 70)
        }
    }

