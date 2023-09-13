//
//  AccountViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import Foundation

class AccountViewModel: ObservableObject {
    @Published var user: User
    
    init(user: User) {
        self.user = user
    }
}
