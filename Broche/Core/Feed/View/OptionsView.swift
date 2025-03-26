//
//  OptionsView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/13/23.
//

import SwiftUI

enum OptionsItemModel: Int, Identifiable, Hashable, CaseIterable {
    case sharepost
    case delete
    
    
    var title: String {
        switch self {
        case .sharepost:
            return "Share Post"
        case .delete:
            return "Delete"
        }
    }
    
    var imageName: String {
        switch self {
        case .sharepost:
            return "paperplane.circle"
        case .delete:
            return "trash"
        }
    }
    var id: Int { return self.rawValue }
}

struct OptionsView: View {
    @Binding var selectedOption: OptionsItemModel?
    let showDeleteOption: Bool
    let post: Post // Add Post to generate the share link
    @Environment(\.dismiss) var dismiss
    @State private var copied = false // State to show "Copied!" feedback
    
    // Generate the share link
    private var shareLink: String {
        "https://travelbroche.com/p/\(post.id ?? "")" // Replace with your domain
    }
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 32, height: 4)
                .foregroundColor(.gray)
                .padding()
            
            List {
                if showDeleteOption {
                    OptionsRowView(model: .delete)
                        .onTapGesture {
                            selectedOption = .delete
                            dismiss()
                        }
                }
                
                HStack {
                    OptionsRowView(model: .sharepost)
                    if copied {
                        Text("Copied!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .transition(.opacity)
                    }
                }
                .onTapGesture {
                    copyToClipboard()
                    selectedOption = .sharepost
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = shareLink
        withAnimation {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copied = false
            }
            dismiss() // Dismiss after 2 seconds
        }
    }
}

struct OptionsRowView: View {
    let model: OptionsItemModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: model.imageName)
                .imageScale(.medium)
            
            Text(model.title)
                .font(.subheadline)
            
        }
    }
    
}


struct OptionsView_Previews: PreviewProvider {
    static var previews: some View {
        OptionsView(selectedOption: .constant(nil), showDeleteOption: false, post: Post.MOCK_POSTS[1])
    }
}
