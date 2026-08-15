//
//  Memory.swift
//  Broche
//
//  Created by Jacob Johnson on 11/29/25.
//

import Foundation

struct Memory: Identifiable, Codable {
    let id = UUID()
    var imageURL: String?       // Remote URL for photo
    var videoURL: String?       // Remote URL for video
    var thumbnailURL: String?   // Low-res thumbnail for reel
    var caption: String?
    var date: Date
    var order: Int              // For reordering
    
    var isVideo: Bool { videoURL != nil }
    
    // Fake data for testing
    static var mockMemories: [Memory] = [
            // 2015
            Memory(imageURL: "https://picsum.photos/id/1015/1080/1920",
                   thumbnailURL: "https://picsum.photos/id/1015/400/711",
                   date: Date.from(year: 2015, month: 6, day: 15), order: 0),
            
            Memory(videoURL: "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4", // ← REAL VERTICAL 9:16
                   thumbnailURL: "https://picsum.photos/id/1018/400/711",
                   date: Date.from(year: 2015, month: 6, day: 16), order: 1),
            
            Memory(imageURL: "https://picsum.photos/id/1019/1080/1920",
                   thumbnailURL: "https://picsum.photos/id/1019/400/711",
                   date: Date.from(year: 2015, month: 6, day: 17), order: 2),
            
            // 2018
            Memory(videoURL: "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4", // ← REAL VERTICAL
                   thumbnailURL: "https://picsum.photos/id/103/400/711",
                   date: Date.from(year: 2018, month: 8, day: 10), order: 3),
            
            Memory(imageURL: "https://picsum.photos/id/104/1080/1920",
                   thumbnailURL: "https://picsum.photos/id/104/400/711",
                   date: Date.from(year: 2018, month: 8, day: 11), order: 4),
            
            // 2023
            Memory(imageURL: "https://picsum.photos/id/1074/1080/1920",
                   thumbnailURL: "https://picsum.photos/id/1074/400/711",
                   date: Date.from(year: 2023, month: 5, day: 20), order: 5),
            
            Memory(videoURL: "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4", // ← REAL VERTICAL
                   thumbnailURL: "https://picsum.photos/id/1025/400/711",
                   date: Date.from(year: 2023, month: 5, day: 21), order: 6),
            
            Memory(imageURL: "https://picsum.photos/id/1039/1080/1920",
                   thumbnailURL: "https://picsum.photos/id/1039/400/711",
                   date: Date.from(year: 2023, month: 5, day: 22), order: 7),
        ]
    }
// Helper to make dates easy
extension Date {
    static func from(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}

struct MemoryGroup: Identifiable {
    let id = UUID()
    let year: Int
    let memories: [Memory]
}
