//
//  SearchFilterView.swift
//  Broche
//
//  Created by Jacob Johnson on 7/13/23.
//

import SwiftUI

struct SearchFilterView: View {
    @Binding var selectedFilter: SearchFilterSelector
    @Namespace var animation
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SearchFilterSelector.allCases, id: \.rawValue) { item in
                ZStack {
                    if selectedFilter == item {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white : Color.black)
                            .matchedGeometryEffect(id: "filterBackground", in: animation)
                    }
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(
                            selectedFilter == item
                                ? (colorScheme == .dark ? .black : .white)
                                : .secondary
                        )
                        .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedFilter = item
                    }
                }
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

struct SearchFilterView_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilterView(selectedFilter: .constant(.accounts))
    }
}
