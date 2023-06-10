//
//  FeedView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct FeedView: View {
    @StateObject var viewModel = FeedViewModel()
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 32) {
                    ForEach(viewModel.posts) { post in
                        FeedCell(viewModel: FeedCellViewModel(post: post))
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                            Task { try await viewModel.fetchPosts() }
                        }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Broche")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(width: 100, height: 32)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: ConversationsView(),
                        label: {
                            Image(systemName: "paperplane")
                                .imageScale(.large)
                                .scaledToFit()
                        })
                }
            }
            .refreshable {
                Task { try await viewModel.fetchPosts() }
            }
            .navigationDestination(for: User.self) { user in
                ProfileView(user: user)
            }
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
