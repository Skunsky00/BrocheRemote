//
//  MarkersheetViewModel2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import Foundation


// Consolidated ViewModel for sheet
class MarkerSheetViewModel2: ObservableObject {
    @Published var user: User
    @Published var location: Location
    let type: MarkerType
    
    init(user: User, location: Location, type: MarkerType) {
        self.user = user
        self.location = location
        self.type = type
    }
}
