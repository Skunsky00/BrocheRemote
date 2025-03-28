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
    case pinToBroche // New option
    
    var title: String {
        switch self {
        case .sharepost: return "Share Post"
        case .delete: return "Delete"
        case .pinToBroche: return "Pin to Broche"
        }
    }
    
    var imageName: String {
        switch self {
        case .sharepost: return "paperplane.circle"
        case .delete: return "trash"
        case .pinToBroche: return "pin.fill"
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
    @State private var viewModel: BrocheGridViewModel? // Hold it here temporarily
    
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
                
                OptionsRowView(model: .pinToBroche)
                    .onTapGesture {
                        selectedOption = .pinToBroche
                        setupViewModel()
                        showPinPicker = true
                    }
            }
            .listStyle(PlainListStyle())
            .sheet(isPresented: $showPinPicker) {
                PinPickerView(post: post, pinnedPosts: viewModel?.pinnedPosts ?? []) { position in
                    pinPost(at: position)
                    dismiss()
                }
                .presentationDetents([.height(200)])
            }
        }
    }
    
    private func setupViewModel() {
        guard let currentUser = Auth.auth().currentUser else { return }
        let user = User(id: currentUser.uid, username: currentUser.displayName ?? "", email: currentUser.email ?? "")
        viewModel = BrocheGridViewModel(user: user)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = shareLink
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
            dismiss()
        }
    }
    
    private func pinPost(at position: Int) {
        guard let viewModel = viewModel else { return }
        viewModel.pinPost(post, at: position)
    }
}

struct PinPickerView: View {
    let post: Post
    let pinnedPosts: [Post?]
    let onPin: (Int) -> Void
    @State private var selectedPosition = 0
    
    var body: some View {
        VStack {
            Text("Pin \(post.caption.prefix(20))... to Position")
                .font(.headline)
                .padding()
            
            Picker("Position", selection: $selectedPosition) {
                ForEach(0..<9) { i in
                    Text("\(i + 1) \(pinnedPosts[i] != nil ? "(Taken)" : "")")
                        .tag(i)
                }
            }
            .pickerStyle(.menu)
            
            Button("Pin") {
                onPin(selectedPosition)
            }
            .font(.subheadline)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
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
