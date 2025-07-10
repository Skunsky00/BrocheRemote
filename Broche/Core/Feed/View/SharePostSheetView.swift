//
//  SharePostSheetView.swift
//  Broche
//
//  Created by Jacob Johnson on 7/9/25.
//

import SwiftUI

struct SharePostSheetView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SearchViewModel(config: .following(Auth.auth().currentUser?.uid ?? ""))
    @State private var copied = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Section 1: Users to share in-app
                Text("Send to")
                    .font(.headline)
                    .padding(.top)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.users) { user in
                            Button {
                                sendInApp(to: user)
                            } label: {
                                UserCell(user: user)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Divider().padding(.vertical, 10)

                // Section 2: Share options
                VStack(spacing: 16) {
                    Button {
                        copyLink()
                    } label: {
                        HStack {
                            Image(systemName: "link")
                            Text(copied ? "Copied!" : "Copy Link")
                        }
                        .font(.subheadline)
                    }

                    Button {
                        shareExternally()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share via Messages or Other Apps")
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Share Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func sendInApp(to user: User) {
        // Your custom logic to send a post as a message (like Instagram DM)
        // For now, you could simulate by creating a Message with a thumbnail of the post.
        print("📨 Send post to \(user.username)")
    }

    func copyLink() {
        UIPasteboard.general.string = "https://travelbroche.com/p/\(post.id ?? "")"
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    func shareExternally() {
        let url = URL(string: "https://travelbroche.com/p/\(post.id ?? "")")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
}

