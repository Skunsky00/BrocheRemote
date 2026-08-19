//
//  ProfileFilterSelector.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import Foundation

enum ProfileFilterSelector: String, CaseIterable {
    case map
    case posts
    case hearts
    case trips        // NEW

    var icon: String {
        switch self {
        case .map: return "map"
        case .posts: return "square.grid.2x2"
        case .hearts: return "heart"
        case .trips: return "airplane"          // NEW
        }
    }
}
