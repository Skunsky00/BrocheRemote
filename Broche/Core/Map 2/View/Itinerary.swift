//
//  Itinerary.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI

struct Itinerary: View {
    let userId: String
    let user: User                          // NEW — needed to launch TripPinSelectorView
    var canCreateTrip: Bool = false         // NEW — true only when shown from MapView2
    @StateObject private var viewModel = ItineraryViewModel()
    var onSelectTrip: ((Trip) -> Void)? = nil
    
    @State private var showTripSelector = false   // NEW
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your Trips")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Achievements")
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                StatBlock(
                    icon: "mappin.circle.fill",
                    label: "States",
                    count: viewModel.travelStats.visitedStates,
                    total: 50,
                    color: Color(.sRGB, red: 76/255, green: 175/255, blue: 80/255)
                )
                StatBlock(
                    icon: "globe.americas.fill",
                    label: "Countries",
                    count: viewModel.travelStats.visitedCountries,
                    total: 195,
                    color: Color(.sRGB, red: 33/255, green: 150/255, blue: 243/255)
                )
                StatBlock(
                    icon: "globe",
                    label: "Continents",
                    count: viewModel.travelStats.visitedContinents,
                    total: 7,
                    color: Color(.sRGB, red: 255/255, green: 193/255, blue: 7/255)
                )
            }
            .padding(.horizontal)
            
            achievementsRow
            
            HStack {
                Text("Trips")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if canCreateTrip {
                    Button {
                        showTripSelector = true
                    } label: {
                        Label("Create", systemImage: "plus.circle.fill")
                            .font(.subheadline.bold())
                    }
                }
            }
            .padding(.horizontal, canCreateTrip ? 0 : 0)
            
            if viewModel.trips.isEmpty {
                Text("No trips yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                TripListView(trips: viewModel.trips, onSelectTrip: { trip in
                    onSelectTrip?(trip)
                }, onDeleteTrip: canCreateTrip ? { trip in
                    viewModel.deleteTrip(userId: userId, tripId: trip.id)
                } : nil)
                .padding(.horizontal, 10)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            if viewModel.visited.isEmpty {
                viewModel.fetchItinerary(userId: userId)
            }
        }
        .sheet(isPresented: $viewModel.showSheet) {
            Text("Itinerary Details Sheet")
                .font(.title2)
                .padding()
        }
        .sheet(isPresented: $showTripSelector) {
            TripPinSelectorView(user: user)
        }
        .onChange(of: showTripSelector) {
            // Refresh trip list after closing the selector, in case a trip was just created
            if !showTripSelector {
                viewModel.fetchTrips(userId: userId)
            }
        }
    }
    
    private var achievementsRow: some View {
        Group {
            if viewModel.isLoadingStats {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                HStack(spacing: 6) {
                    ForEach(viewModel.badges) { badge in
                        BadgeItem(
                            title: badge.title,
                            color: badge.color,
                            isUnlocked: badge.isUnlocked
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
    }
}

struct BadgeItem: View {
    let title: String
    let color: Color
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(isUnlocked ? color : color.opacity(0.25))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isUnlocked ? color : Color.clear, lineWidth: 2)
                        .frame(width: 46, height: 46)
                )

            Text(title)
                .font(.system(size: 10))
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}


struct StatBlock: View {
    let icon: String
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(color)
            
            Text("\(count) / \(total)\n\(label)")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Custom FlowLayout to mimic Android's FlowRow
struct FlowLayout<Data, ID, Content>: View
where Data: RandomAccessCollection, Data.Element: Hashable, ID: Hashable, Content: View {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        spacing: CGFloat,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.id = id
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
            GeometryReader { geometry in
                // Use a single VStack to stack rows
                VStack(alignment: .leading, spacing: spacing) {
                    // Split items into rows based on width
                    ForEach(computeRows(in: geometry.size.width), id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(row, id: id) { element in
                                content(element)
                            }
                        }
                    }
                }
            }
        }
    
    private func computeRows(in maxWidth: CGFloat) -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentWidth: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        
        for element in data {
            // Estimate the width of the content (approximation)
            // Note: For accurate sizing, you may need to measure the actual view size
            let estimatedWidth: CGFloat = 72 + spacing // Based on BadgeItem’s fixed width (72) + spacing
            let estimatedHeight: CGFloat = 72 // Approximate height of BadgeItem
            
            if currentWidth + estimatedWidth <= maxWidth {
                // Add to current row
                rows[rows.count - 1].append(element)
                currentWidth += estimatedWidth
                maxRowHeight = max(maxRowHeight, estimatedHeight)
            } else {
                // Start a new row
                rows.append([element])
                currentWidth = estimatedWidth
                maxRowHeight = estimatedHeight
            }
        }
        
        return rows
    }
}
