//
//  ProfileFilterView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import SwiftUI

struct ProfileFilterBar: View {
    @Binding var selectedFilter: ProfileFilterSelector
    let isCurrentUser: Bool   // NEW
    @Environment(\.colorScheme) var colorScheme

//    private var visibleFilters: [ProfileFilterSelector] {
//        isCurrentUser ? ProfileFilterSelector.allCases : ProfileFilterSelector.allCases.filter { $0 != .bookmarks }
//    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileFilterSelector.allCases, id: \.rawValue) { item in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = item
                    }
                } label: {
                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: selectedFilter == item ? .semibold : .regular))
                        .foregroundStyle(selectedFilter == item ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
    }
}
