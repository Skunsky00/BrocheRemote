//
//  MemoriesViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 11/29/25.
//

import Foundation

class MemoriesViewModel: ObservableObject {
    @Published var memoryGroups: [MemoryGroup] = []
    @Published var allMemories: [Memory] = []
    
    init(locationId: String) {
        loadMockGroupedMemories()
    }
    
    private func loadMockGroupedMemories() {
        let mock = Memory.mockMemories
        
        // Group by year
        let grouped = Dictionary(grouping: mock) { Calendar.current.component(.year, from: $0.date) }
            .map { year, memories in
                MemoryGroup(year: year, memories: memories.sorted { $0.date < $1.date })
            }
            .sorted { $0.year < $1.year }
        
        self.memoryGroups = grouped
        self.allMemories = mock
    }

    
    // Future: Load from Firestore
    func loadMemories(for locationId: String) async {
        // TODO: Fetch from COLLECTION_LOCATIONS.document(userId).collection("memories")...
    }
    
    // Future: Add memory
    func addMemory(_ memory: Memory) async {
        // TODO: Save to Firestore + upload media
    }
}
