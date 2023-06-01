//
//  ProfileFilterView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import SwiftUI

struct ProfileFilterView: View {
    @Binding var selectedFilter: ProfileFilterSelector
    @Namespace var animation
    var body: some View {
        HStack {
            ForEach(ProfileFilterSelector.allCases, id: \.rawValue) { item in
                VStack {
                    Image(systemName: item.imageName)
                        .font(.subheadline)
                        .imageScale(.large)
                        .fontWeight(selectedFilter == item ? .semibold : .regular)
                        .foregroundColor(selectedFilter == item ? .black : . gray)
                    
                    if selectedFilter == item {
                        Capsule()
                            .foregroundColor(.black)
                            .frame(height: 3)
                            .matchedGeometryEffect(id: "filter", in: animation)
                    } else {
                        Capsule()
                            .foregroundColor(.clear)
                            .frame(height: 3)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        self.selectedFilter = item
                    }
                }
            }
        }
        .overlay(Divider().offset(x: 0, y: 16))
        .padding(.top)
    }
}
