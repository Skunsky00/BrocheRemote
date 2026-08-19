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
    @Binding var selectedExistingLocation: Location?
    @EnvironmentObject var viewModel: LocationSearchViewModel2
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                TextField("Search for a location", text: $viewModel.queryFragment)
                    .font(.body)
                    .autocapitalization(.none)
                
                Button {
                    viewModel.queryFragment = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .opacity(viewModel.queryFragment.isEmpty ? 0 : 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal)
            .padding(.top, 12)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.results, id: \.self) { result in
                        Button {
                            selectedExistingLocation = nil
                            viewModel.selectLocation(result)
                            mapState = .locationSelected
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
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
