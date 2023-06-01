//
//  BrocheView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/1/23.
//

import SwiftUI

struct BrocheView: View {
    let user: User
    @ObservedObject var viewModel: ProfileViewModel
    @State private var selectedFilter: ProfileFilterSelector = .hearts
    var body: some View {
        ScrollView {
            LazyVStack {
                switch self.selectedFilter {
                case .hearts:
                    PostGridView(config: .likedPosts(user))
                case .bookmarks:
                    PostGridView(config: .bookmarkedPosts(user))
                case .mappin:
                     PostGridView(config: .profile(user))
                }
                
            }
        }
    }
}
