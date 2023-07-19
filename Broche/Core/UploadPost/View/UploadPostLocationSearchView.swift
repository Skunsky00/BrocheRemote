//
//  UploadPostLocationSearchView.swift
//  Broche
//
//  Created by Jacob Johnson on 7/19/23.
//

import SwiftUI
import MapKit

struct UploadPostLocationSearchView: View {
    @ObservedObject var viewModel: UploadPostSearchViewModel
    @Binding var location: String
    @Binding var isShowingLocationSearch: Bool
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocation: MKLocalSearchCompletion?
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
            ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(viewModel.results, id: \.self) { result in
                                    LocationSearchResultCell(title: result.title, subtitle: result.subtitle)
                                        .background(colorScheme == .dark ? Color.black : Color.white)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                viewModel.selectLocation(result)
                                                selectedLocation = result // Set the selected location
                                                presentationMode.wrappedValue.dismiss() // Dismiss the location search view
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
}


//struct UploadPostLocationSearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        UploadPostLocationSearchView(viewModel: <#LocationSearchViewModel#>, location: <#Binding<String>#>, isShowingLocationSearch: <#Binding<Bool>#>)
//    }
//}
