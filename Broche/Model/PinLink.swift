//
//  PinLink.swift
//  Broche
//
//  Created by Jacob Johnson on 10/9/26.
//

import Foundation

struct PinLink: Codable, Identifiable, Hashable {
    var url: String
    var title: String?
    var source: String?
    var addedAt: Date?
 
    var id: String { url }
}
