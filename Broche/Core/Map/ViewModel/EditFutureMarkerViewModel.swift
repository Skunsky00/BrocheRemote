//
//  EditFutureMarkerViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 8/4/23.
//

import Foundation
import SwiftUI
import Firebase

class EditFutureMarkerViewModel: ObservableObject {
    @Published var user: User
    
    @Published var date = ""
    @Published var description = ""
    
    init(user: User) {
        self.user = user
        
        if let date = user.location?.date {
            self.date = date
        }
        if let description = user.location?.description {
            self.description = description
        }
    }
    
    func updateUserData() async throws {
        
    }
}
