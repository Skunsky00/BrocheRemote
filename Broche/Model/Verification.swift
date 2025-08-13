//
//  Verification.swift
//  Broche
//
//  Created by Jacob Johnson on 7/10/25.
//

import Foundation
import SwiftUICore


enum VerificationType: String, Codable {
    case none
    case business
    case trustedTraveler
    
    var badgeColor: Color {
        switch self {
        case .none: return .clear
        case .business: return .blue
        case .trustedTraveler: return .green
        }
    }
    
    var badgeSymbol: String {
        return "checkmark.seal.fill"
    }
}
