//
//  LocationSearchView2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI
import MapKit

struct LocationSearchView2: View {
    @Binding var mapState: MapViewState2
    @EnvironmentObject var viewModel: LocationSearchViewModel2
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search for a location", text: $viewModel.queryFragment)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                
                Button {
                    viewModel.queryFragment = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .opacity(viewModel.queryFragment.isEmpty ? 0 : 1)
                }
            }
            .padding()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.results, id: \.self) { result in
                        Button {
                            viewModel.selectLocation(result)
                            mapState = .locationSelected
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical)
            }
            .frame(maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}
