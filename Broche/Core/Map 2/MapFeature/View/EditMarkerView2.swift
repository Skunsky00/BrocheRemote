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
    
    init(user: User, location: Location, type: MarkerType) {
        _viewModel = StateObject(wrappedValue: EditMarkerViewModel2(user: user, location: location, type: type))
    }
    
    var body: some View {
        VStack {
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Text("Edit Pin").font(.subheadline).fontWeight(.semibold)
                Spacer()
                Button {
                    Task {
                        try await viewModel.updateUserData()
                        dismiss()
                    }
                } label: {
                    Text("Done").font(.subheadline).fontWeight(.bold)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            EditMarkerRowView2(title: "Date", placeholder: "13, Aug, 2023", text: $viewModel.date)
            EditMarkerRowView2(title: "Description", placeholder: "Add details...", text: $viewModel.description)
            
            if viewModel.type == .visited {
                EditMarkerRowView2(title: "Link", placeholder: "Add link here", text: $viewModel.link)
                if !viewModel.link.isEmpty {
                    Button("Clear Link") {
                        viewModel.link = ""
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
            }
            
            Spacer()
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
