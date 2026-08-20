//
//  SearchView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct SearchView: View {
    @State private var selectedFilter: SearchFilterSelector = .accounts
    
    var body: some View {
        NavigationStack {
            ScrollView {
                SearchFilterView(selectedFilter: $selectedFilter)
                searchView
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var searchView: some View {
        ScrollView {
            LazyVStack {
                switch self.selectedFilter {
                case .discover:
                    SuggestedFollowsView()
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
