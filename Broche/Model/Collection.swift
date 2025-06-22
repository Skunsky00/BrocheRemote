//
//  Collection.swift
//  Broche
//
//  Created by Jacob Johnson on 6/14/25.
//

import Foundation
import FirebaseFirestore

struct Collection: Identifiable, Codable {
    var id: String?
    let name: String
    let postIds: [String]
    let createdAt: Date
    let thumbnailUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case postIds
        case createdAt
        case thumbnailUrl
    }

    init(id: String?, name: String, postIds: [String] = [], createdAt: Date = Date(), thumbnailUrl: String? = nil) {
        self.id = id
        self.name = name
        self.postIds = postIds
        self.createdAt = createdAt
        self.thumbnailUrl = thumbnailUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.postIds = try container.decodeIfPresent([String].self, forKey: .postIds) ?? []
        self.thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)

        // Handle both Timestamp and Long (milliseconds) for createdAt
        do {
            let timestamp = try container.decode(Timestamp.self, forKey: .createdAt)
            self.createdAt = timestamp.dateValue()
        } catch {
            // Try decoding as Long (Android legacy data)
            let milliseconds = try container.decode(Int64.self, forKey: .createdAt)
            self.createdAt = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(postIds, forKey: .postIds)
        try container.encode(ISO8601DateFormatter().string(from: createdAt), forKey: .createdAt)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
    }
}
