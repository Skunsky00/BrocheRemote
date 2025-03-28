//
//  Location 2.swift
//  Broche
//
//  Created by Jacob Johnson on 5/8/25.
//

import Foundation
struct Location: Codable, Identifiable {
    @DocumentID var id: String?
    let ownerUid: String
    let latitude: Double
    let longitude: Double
    let city: String?
    let date: String?
    let description: String?
    let link: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerUid
        case latitude
        case longitude
        case city
        case date
        case description
        case link
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.ownerUid = try container.decodeIfPresent(String.self, forKey: .ownerUid) ?? ""
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0.0
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0.0
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.date = try container.decodeIfPresent(String.self, forKey: .date)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.link = try container.decodeIfPresent(String.self, forKey: .link)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerUid, forKey: .ownerUid)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(city, forKey: .city)
        try container.encode(date, forKey: .date)
        try container.encode(description, forKey: .description)
        try container.encode(link, forKey: .link)
    }
}

struct Location: Codable, Identifiable {
    @DocumentID var id: String?
    let ownerUid: String
    let latitude: Double
    let longitude: Double
    let city: String?
    let date: String?
    let description: String?
    let link: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerUid
        case latitude
        case longitude
        case city
        case date
        case description
        case link
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        self.ownerUid = try container.decodeIfPresent(String.self, forKey: .ownerUid) ?? ""
        self.latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0.0
        self.longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0.0
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.date = try container.decodeIfPresent(String.self, forKey: .date)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.link = try container.decodeIfPresent(String.self, forKey: .link)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerUid, forKey: .ownerUid)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(city, forKey: .city)
        try container.encode(date, forKey: .date)
        try container.encode(description, forKey: .description)
        try container.encode(link, forKey: .link)
    }
}
