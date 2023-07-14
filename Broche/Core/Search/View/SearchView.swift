//
//  SearchView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct SearchView: View {
    @State private var selectedFilter: SearchFilterSelector = .posts
    
    var body: some View {
        NavigationStack {
            ScrollView {
                SearchFilterView(selectedFilter: $selectedFilter)
                
                searchView
//                    .padding(.top, -0)
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: User.self) { user in
                                ProfileView(user: user)
                            }
        }
    }
    
    
    var searchView: some View {
        ScrollView {
            LazyVStack {
                switch self.selectedFilter {
                case .posts:
                    PostGridView(config: .explore)
                case .accounts:
                    UserListView(config: .search)
                }
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
