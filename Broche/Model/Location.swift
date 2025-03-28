//
//  Location.swift
//  Broche
//
//  Created by Jacob Johnson on 5/8/25.
//

import Foundation
import FirebaseFirestoreSwift

struct Location: Codable, Identifiable {
    var id: String
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
    
    init(id: String, ownerUid: String = "", latitude: Double = 0.0, longitude: Double = 0.0, city: String? = nil, date: String? = nil, description: String? = nil, link: String? = nil) {
        self.id = id
        self.ownerUid = ownerUid
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
        self.date = date
        self.description = description
        self.link = link
    }
}

extension Location {
    static var MOCK_LOCATIONS: [Location] = [
        Location(
            id: UUID().uuidString,
            ownerUid: UUID().uuidString,
            latitude: 40.7128,
            longitude: -74.0060,
            city: "New York",
            date: "2023-10-01",
            description: "Visited Central Park",
            link: "https://example.com/nyc"
        ),
        Location(
            id: UUID().uuidString,
            ownerUid: UUID().uuidString,
            latitude: 48.8566,
            longitude: 2.3522,
            city: "Paris",
            date: "2023-11-15",
            description: "Eiffel Tower visit",
            link: "https://example.com/paris"
        ),
        Location(
            id: UUID().uuidString,
            ownerUid: UUID().uuidString,
            latitude: -33.8688,
            longitude: 151.2093,
            city: "Sydney",
            date: "2024-01-20",
            description: "Sydney Opera House",
            link: "https://example.com/sydney"
        )
    ]
}
