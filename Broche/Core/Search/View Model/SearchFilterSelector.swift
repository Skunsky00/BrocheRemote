//
//  SearchFilterSelector.swift
//  Broche
//
//  Created by Jacob Johnson on 7/13/23.
//

import Foundation

enum SearchFilterSelector: Int, CaseIterable {
    case discover
    case accounts
    
    var title: String {
        switch self {
        case .discover:
            return "Discover"
        case .accounts:
            return "Accounts"
        }
    }
}
