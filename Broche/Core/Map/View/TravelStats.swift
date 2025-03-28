//
//  TravelStats.swift
//  Broche
//
//  Created by Jacob Johnson on 5/8/25.
//


```swift
import SwiftUI
import CoreLocation

struct TravelStats {
    let visitedStates: Int
    let visitedCountries: Int
    let visitedContinents: Int
    let unlockedContinents: [String]
    
    init(visitedStates: Int = 0, visitedCountries: Int = 0, visitedContinents: Int = 0, unlockedContinents: [String] = []) {
        self.visitedStates = visitedStates
        self.visitedCountries = visitedCountries
        self.visitedContinents = visitedContinents
        self.unlockedContinents = unlockedContinents
    }
}

struct Badge {
    let title: String
    let description: String
    let color: Color
    let isUnlocked: Bool
}

struct Location {
    let latitude: Double
    let longitude: Double
}
```