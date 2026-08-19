//
//  Visit.swift
//  Broche
//
//  Created by Jacob Johnson on 8/15/26.
//

import Foundation

struct Visit: Codable, Identifiable {
    var id: String
    let ownerUid: String
    let locationId: String
    var name: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerUid
        case locationId
        case name
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.ownerUid = try container.decodeIfPresent(String.self, forKey: .ownerUid) ?? ""
        self.locationId = try container.decodeIfPresent(String.self, forKey: .locationId) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerUid, forKey: .ownerUid)
        try container.encode(locationId, forKey: .locationId)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
    }

    init(id: String, ownerUid: String, locationId: String, name: String, createdAt: Date = Date()) {
        self.id = id
        self.ownerUid = ownerUid
        self.locationId = locationId
        self.name = name
        self.createdAt = createdAt
    }
}
