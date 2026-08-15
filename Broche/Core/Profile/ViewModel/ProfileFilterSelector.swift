//
//  ProfileFilterSelector.swift
//  Broche
//
//  Created by Jacob Johnson on 5/29/23.
//

import Foundation

enum ProfileFilterSelector: Int, CaseIterable {
    case broche // New default tab
    case hearts
    case bookmarks
    
    var imageName: String {
        switch self {
        case .broche: return "pin.fill" // Icon for pinned posts
        case .hearts: return "heart.fill"
        case .bookmarks: return "bookmark.fill"
        }
    }
}
