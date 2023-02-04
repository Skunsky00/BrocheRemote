//
//  ProfileView2.swift
//  Broche
//
//  Created by Jacob Johnson on 12/14/22.
//

import SwiftUI

struct ProfileView2: View {
    let user: User
    @ObservedObject var viewModel: ProfileViewModel
    @State private var selectedFilter: ProfileFilterSelector = .hearts
    @Namespace var animation
    
    init(user: User) {
        self.user = user
        self.viewModel = ProfileViewModel(user: user)
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                ProfileHeaderView(viewModel: viewModel)
                
                profileFilterBar
                
                brocheView
                
               
            }.padding(.top)
        }
    }
    
    var profileFilterBar: some View {
        
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
    }
}

var brocheView: some View {
    ScrollView {
        LazyVStack {
            PostGridView()
        }
    }
}




