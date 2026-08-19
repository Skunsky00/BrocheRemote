//
//  LoginViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 5/22/23.
//

import Foundation
import FirebaseAuth

@MainActor
class LoginViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false

    func signIn(withEmail email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.login(withEmail: email, password: password)
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
        isLoading = false
    }

    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        let code = AuthErrorCode.Code(rawValue: nsError.code)   // CHANGED — explicit .Code
        
        switch code {
        case .wrongPassword, .userNotFound, .invalidCredential:
            return "Incorrect email or password. Please try again."
        case .invalidEmail:
            return "That email address doesn't look right."
        case .userDisabled:
            return "This account has been disabled. Contact support if you think this is a mistake."
        case .networkError:
            return "Network error. Check your connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
