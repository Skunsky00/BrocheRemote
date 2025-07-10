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
    @StateObject private var viewModel = SharePostViewModel()
    @State private var searchText = ""
    @State private var copied = false
    @State private var showShareSheet = false

    // Define the grid layout: 3 columns, adaptive width
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16),
        GridItem(.adaptive(minimum: 100), spacing: 16),
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]

    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.followingUsers
        }
        let term = searchText.lowercased()
        return viewModel.followingUsers.filter {
            $0.username.lowercased().contains(term) ||
            $0.fullname?.lowercased().contains(term) ?? false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Debug Info
            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding()
            }

            // Search Bar
            TextField("Search users...", text: $searchText)
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding(.vertical)
                .padding(.horizontal)

            // User Grid
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading following users...")
                        .padding(.top, 20)
                } else if viewModel.followingUsers.isEmpty {
                    Text("You’re not following anyone yet.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredUsers) { user in
                            VStack(spacing: 8) {
                                CircularProfileImageView(user: user, size: .medium)
                                Text(user.username)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                            }
                            .padding(8)
                            .onTapGesture {
                                viewModel.sendPost(to: user, post: post)
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }

            Spacer()

            // Divider
            Divider()
                .padding(.vertical, 12)

            // Bottom Action Buttons
            HStack(spacing: 40) {
                // Share
                VStack {
                    Button {
                        showShareSheet = true
                    } label: {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(Image(systemName: "paperplane.fill").foregroundColor(.white))
                    }
                    Text("Share")
                        .font(.caption)
                }

                // Copy Link
                VStack {
                    Button {
                        UIPasteboard.general.string = post.shareLink
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 60, height: 60)
                            .overlay(Image(systemName: "link").foregroundColor(.white))
                    }
                    Text(copied ? "Copied!" : "Copy Link")
                        .font(.caption)
                }

                // Messages shortcut
                VStack {
                    Button {
                        print("Messages tapped")
                        dismiss()
                    } label: {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 60, height: 60)
                            .overlay(Image(systemName: "message.fill").foregroundColor(.white))
                    }
                    Text("Messages")
                        .font(.caption)
                }
            }
            .padding(.bottom, 24)
        }
        .onAppear {
            print("🔔 SharePostSheetView appeared")
            viewModel.fetchFollowingUsers()
        }
        .onChange(of: viewModel.followingUsers) { newValue in
            print("🔔 followingUsers changed: \(newValue.count) users")
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [URL(string: post.shareLink)!])
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private extension Post {
    var shareLink: String {
        "https://travelbroche.com/p/\(id ?? "")"
    }
}


struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
