//
//  OptionsView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/13/23.
//

import SwiftUI
import FirebaseAuth

enum OptionsItemModel: Int, Identifiable, Hashable, CaseIterable {
    case sharepost
    case delete
    case emptyview
    
    var title: String {
        switch self {
        case .sharepost: return "Share Post"
        case .delete: return "Delete"
        case .emptyview: return ""
        }
    }
    
    var imageName: String {
        switch self {
        case .sharepost: return "paperplane.circle"
        case .delete: return "trash"
        case .emptyview: return ""
        }
    }
    var id: Int { return self.rawValue }
}

struct OptionsView: View {
    @Binding var selectedOption: OptionsItemModel?
    let showDeleteOption: Bool
    let post: Post
    @Environment(\.dismiss) var dismiss
    @State private var copied = false
    @State private var showPinPicker = false
    @State private var viewModel: BrocheGridViewModel?
    
    private var shareLink: String {
        "https://travelbroche.com/p/\(post.id ?? "")"
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
                
                OptionsRowView(model: .sharepost)
                    .onTapGesture {
                        selectedOption = .sharepost
                        dismiss() // Dismiss OptionsView
                    }
                
                OptionsRowView(model: .emptyview)
                
            }
            .listStyle(PlainListStyle())
            
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
