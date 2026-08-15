//
//  ProfileFilterView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import SwiftUI

struct ProfileFilterView: View {
    @Binding var selectedFilter: ProfileFilterSelector?
    @Namespace var animation
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProfileFilterSelector.allCases, id: \.rawValue) { item in
                ZStack {
                    if selectedFilter == item {
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.08))
                            .matchedGeometryEffect(id: "filterBG", in: animation)
                    }
                    Image(systemName: item.imageName)
                        .font(.system(size: 15, weight: selectedFilter == item ? .semibold : .regular))
                        .foregroundColor(selectedFilter == item ? (colorScheme == .dark ? .white : .black) : .gray)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedFilter = selectedFilter == item ? nil : item
                    }
                }
            }
        }
        .padding(4)
    }
}
