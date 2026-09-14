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
    @FocusState private var isFocused: Bool
 
    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal)
                .padding(.top, 12)
 
            if viewModel.queryFragment.isEmpty {
                emptyState
            } else if viewModel.results.isEmpty {
                noResultsState
            } else {
                resultsList
            }
        }
        .background(
            ZStack(alignment: .top) {
                Color(.systemBackground)
                LinearGradient.brocheHorizon
                    .frame(height: 160)
            }
        )
        .cornerRadius(16)
        .onAppear { isFocused = true }
    }
 
    // MARK: - Search field
 
    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.north.circle.fill")
                .font(.title3)
                .foregroundStyle(LinearGradient.brocheStroke)
 
            TextField("Search a place or address", text: $viewModel.queryFragment)
                .font(.body)
                .autocapitalization(.none)
                .focused($isFocused)
 
            if !viewModel.queryFragment.isEmpty {
                Button {
                    viewModel.queryFragment = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
 
    // MARK: - Empty state (before typing)
 
    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 40)
            Image(systemName: "safari")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(LinearGradient.brocheStroke)
            Text("Every pin starts here")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(.primary)
            Text("Search a city, landmark, or address to add it to your map.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
 
    // MARK: - No results
 
    private var noResultsState: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 40)
            Image(systemName: "mappin.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            Text("No places found")
                .font(.system(.body, design: .serif))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
 
    // MARK: - Results
 
    private var resultsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(viewModel.results, id: \.self) { result in
                    Button {
                        selectedExistingLocation = nil
                        isFocused = false
                        viewModel.selectLocation(result)
                        mapState = .locationSelected
                    } label: {
                        LocationSearchResultCell2(
                            title: result.title,
                            subtitle: result.subtitle,
                            isPointOfInterest: !result.subtitle.isEmpty && result.subtitle.first?.isNumber != true
                        )
                    }
                    .buttonStyle(.plain)
 
                    Divider().padding(.leading, 62)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
