//
//  Location2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import Foundation
import FirebaseFirestoreSwift


struct Location2: Codable, Identifiable, Equatable {
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
