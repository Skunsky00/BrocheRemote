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
    
    var selectedTextColor: Color {
            colorScheme == .dark ? .white : .black
        }
        
        var selectedCapsuleColor: Color {
            colorScheme == .dark ? .white : .black
        }
    var body: some View {
        HStack {
            ForEach(SearchFilterSelector.allCases, id: \.rawValue) { item in
                VStack {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(selectedFilter == item ? .semibold : .regular)
                        .foregroundColor(selectedFilter == item ? selectedTextColor : .gray)
                    
                    if selectedFilter == item {
                        Capsule()
                            .foregroundColor(selectedCapsuleColor)
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
        .foregroundColor(colorScheme == .dark ? .white : .primary)
                .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct SearchFilterView_Previews: PreviewProvider {
    static var previews: some View {
        SearchFilterView(selectedFilter: .constant(.posts))
    }
}
