//
//  Trip.swift
//  Broche
//
//  Created by Jacob Johnson on 8/10/26.
//

import Foundation

struct Trip: Codable, Identifiable {
    var id: String
    let ownerUid: String
    var name: String
    var locationIds: [String]   // references into COLLECTION_LOCATION (visited only)
    var createdAt: Date
    var coverImageUrl: String?
}
