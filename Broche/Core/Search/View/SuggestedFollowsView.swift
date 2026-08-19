//
//  SuggestedFollowsView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/15/26.
//

import SwiftUI

struct SuggestedFollowsView: View {
    @StateObject private var viewModel = SuggestedFollowsViewModel()

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.users) { user in
                SuggestedUserCard(user: user) {
                    viewModel.toggleFollow(user)
                }
                .onAppear {
                    if user.id == viewModel.users.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .task {
            await viewModel.loadInitial()
        }
    }
}

struct SuggestedUserCard: View {
    let user: User
    let onFollowToggle: () -> Void

    var body: some View {
        NavigationLink(value: user) {
            HStack(spacing: 12) {
                CircularProfileImageView(user: user, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(user.username)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let fullname = user.fullname {
                        Text(fullname)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    onFollowToggle()
                } label: {
                    Text(user.isFollowed == true ? "Following" : "Follow")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(user.isFollowed == true ? Color.primary : Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(user.isFollowed == true ? Color(.secondarySystemBackground) : Color.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
