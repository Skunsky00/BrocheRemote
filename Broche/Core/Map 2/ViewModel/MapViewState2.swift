//
//  MapViewState2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import Foundation
import SwiftUI


// Enum for marker types to consolidate logic
enum MarkerType: String {
    case visited
    case future
}

// Updated MapViewState enum
enum MapViewState2 {
    case noInput
    case searchingForLocation
    case locationSelected
}

enum PinType: String, CaseIterable, Identifiable {
    case visited = "Visited"
    case future = "Future Visits"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .visited: "mappin.circle"
        case .future: "airplane.departure"
        }
    }
    
    var iconFilled: String {
        switch self {
        case .visited: "mappin.circle.fill"
        case .future: "airplane.arrival"
        }
    }
    
    var color: Color {
        switch self {
        case .visited: .red      // BRIGHT RED
        case .future: .blue      // BRIGHT BLUE
        }
    }
    
    var markerType: MarkerType {
        switch self {
        case .visited: return .visited
        case .future: return .future
        }
    }
}
