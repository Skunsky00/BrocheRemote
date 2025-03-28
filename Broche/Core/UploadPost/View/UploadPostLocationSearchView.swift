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
    @Binding var selectedLocation: MKLocalSearchCompletion?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button {
                    print("DEBUG: Cancel location search")
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                TextField("Search Location", text: $viewModel.queryFragment)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            Divider()
                .padding(.vertical, 8)
            
            // Results
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.results, id: \.self) { result in
                        LocationSearchResultCell(title: result.title, subtitle: result.subtitle)
                            .padding(.horizontal)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .onTapGesture {
                                print("DEBUG: Selected location: \(result.title)")
                                viewModel.selectLocation(result)
                                selectedLocation = result
                                location = result.title
                                dismiss()
                            }
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .navigationBarHidden(true)
    }
}



