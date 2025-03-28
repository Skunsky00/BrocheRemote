//
//  Itinerary.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI

struct Itinerary: View {
    let userId: String
    @StateObject private var viewModel = ItineraryViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your Itinerary")
                .font(.title)
                .fontWeight(.bold)
            
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
            
            Text("Achievements")
                .font(.title3)
                .fontWeight(.semibold)
            
            FlowLayout(
                data: viewModel.badges,
                id: \.id,
                spacing: 10
            ) { badge in
                BadgeItem(
                    title: badge.title,
                    color: badge.color,
                    isUnlocked: badge.isUnlocked
                )
            }
            .padding(.horizontal, 10)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // Prevent multiple fetches
            if viewModel.visited.isEmpty {
                viewModel.fetchItinerary(userId: userId)
            }
        }
        .sheet(isPresented: $viewModel.showSheet) {
            Text("Itinerary Details Sheet")
                .font(.title2)
                .padding()
        }
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

struct BadgeItem: View {
    let title: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(isUnlocked ? 1 : 0.3))
                .frame(width: 48, height: 48)
            
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundColor(color.opacity(isUnlocked ? 1 : 0.3))
                .frame(width: 72)
        }
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

struct Itinerary_Previews: PreviewProvider {
    static var previews: some View {
        Itinerary(userId: "testUser")
    }
}
