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
    @Environment(\.colorScheme) var colorScheme
    
    var selectedTextColor: Color {
            colorScheme == .dark ? .white : .black
        }
        
        var selectedCapsuleColor: Color {
            colorScheme == .dark ? .white : .black
        }
    
    var body: some View {
        
        
        
        HStack {
            ForEach(ProfileFilterSelector.allCases, id: \.rawValue) { item in
                VStack {
                    Image(systemName: item.imageName)
                        .font(.subheadline)
                        .imageScale(.large)
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
