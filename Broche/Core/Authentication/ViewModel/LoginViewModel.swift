//
//  LoginViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/22/23.
//

import Foundation

class LoginViewModel: ObservableObject {
    func signIn(withEmail email: String, password: String) async throws {
        try await AuthService.shared.login(withEmail: email, password: password)
    }
}
