//
//  LocationSearchView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/8/23.
//

import SwiftUI

struct LocationSearchView: View {
    @Binding var mapState: MapViewState
    @EnvironmentObject var viewModel: LocationSearchViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            //header view
            
            HStack {
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 6, height: 6)
                
                TextField("Search Location", text: $viewModel.queryFragment)
                    .frame(height: 32)
                    .background(Color.gray)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.trailing)
            }.padding(.horizontal)
                .padding(.top, 64)
            
            Divider()
                .padding(.vertical)
                
            //list view
            ScrollView{
                VStack(alignment: .leading) {
                    ForEach(viewModel.results, id: \.self) { result in
                        LocationSearchResultCell(title: result.title, subtitle: result.subtitle)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .onTapGesture {
                                withAnimation(.spring()){
                                    viewModel.selectLocation(result)
                                    mapState = .locationSelected
                                }
                            }
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchView(mapState: .constant(.searchingForLocation))
    }
}
