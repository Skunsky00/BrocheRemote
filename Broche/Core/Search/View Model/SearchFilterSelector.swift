//
//  SearchFilterSelector.swift
//  Broche
//
//  Created by Jacob Johnson on 7/13/23.
//

import Foundation

enum SearchFilterSelector: Int, CaseIterable {
    case posts
    case accounts
    
    var title: String {
        switch self {
        case .posts:
            return "Posts"
        case .accounts:
            return "Accounts"
        }
    }
}
