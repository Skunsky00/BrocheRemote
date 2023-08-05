//
//  FeedView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct FeedView: View {
    @StateObject var viewModel = FeedViewModel()
   // @State private var currentVisiblePost: Post?
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 32) {
                        ForEach(viewModel.posts) { post in
                            FeedCell(viewModel: FeedCellViewModel(post: post))
                                .onAppear {
                                    // Load more posts when the last post is about to appear
                                    if post == viewModel.posts.last {
                                        Task {
                                            try await viewModel.fetchMorePosts()
                                            // Scroll to the newly loaded posts
                                            scrollView.scrollTo(viewModel.lastDocument, anchor: .bottom)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                        }
                    }
                    
                    .navigationTitle("Feed")
                    .navigationBarTitleDisplayMode(.inline)
                    .refreshable {
                        Task {
                            // Clear existing posts before fetching new ones
                            viewModel.posts.removeAll()
                            try await viewModel.fetchPosts()
                        }
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
                    .navigationDestination(for: User.self) { user in
                        ProfileView(user: user)
                    }
                }
            }
        }
    }
}


struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
