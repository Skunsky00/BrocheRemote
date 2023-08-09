//
//  FutureMarkerSheetViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 8/4/23.
//

import Foundation
import SwiftUI

class FutureMarkerSheetViewmodel: ObservableObject {
    @Published var user: User
    @Published var selectedLocation: Location?
    
    init(user: User) {
        self.user = user
    }
}
