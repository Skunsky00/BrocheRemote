//
//  MemoriesReelView.swift
//  Broche
//
//  Created by Jacob Johnson on 11/29/25.
//

import SwiftUI

struct MemoriesReelView: View {
    @ObservedObject var viewModel: MemoriesViewModel
    @State private var selectedGroup: MemoryGroup?
    @State private var showingFullReel = false
    
    var body: some View {
        VStack(spacing: 20) {
            // REMOVED "Memories" title — cleaner
            // Added padding top/bottom
            if viewModel.memoryGroups.isEmpty {
                Text("No memories yet")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.memoryGroups) { group in
                            if let firstMemory = group.memories.first {
                                VStack(spacing: 8) {
                                    // Thumbnail
                                    AsyncImage(url: URL(string: firstMemory.thumbnailURL ?? "")) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay {
                                                if firstMemory.isVideo {
                                                    Image(systemName: "play.circle.fill")
                                                        .font(.system(size: 44))
                                                        .foregroundStyle(.white.opacity(0.9))
                                                }
                                            }
                                    } placeholder: {
                                        Color(.systemGray5)
                                            .frame(width: 120, height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                    
                                    // Year — fixed "2,015" → "2015", smaller text
                                    Text(String(group.year))
                                        .font(.caption.bold())
                                        .foregroundStyle(.primary)
                                }
                                .onTapGesture {
                                    showingFullReel = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(.vertical, 12)  // ← Top & bottom padding
        .fullScreenCover(isPresented: $showingFullReel) {
            YearMemoryReelView(allGroups: viewModel.memoryGroups)
        }
    }
}
