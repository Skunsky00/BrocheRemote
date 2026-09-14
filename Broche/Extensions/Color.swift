//
//  Color.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import SwiftUI

extension Color {
    static var theme = Theme()
    
    struct Theme {
        let systemBackground = Color("SystemBackgroundColor")
        
        // Stops pulled directly from the app's existing brand gradient
        let brocheNavy     = Color(red: 0.015, green: 0.196, blue: 0.274)
        let brocheRose     = Color(red: 0.772, green: 0.274, blue: 0.388)
        let brocheCoral    = Color(red: 1.000, green: 0.408, blue: 0.404)
        let brocheMauve    = Color(red: 0.588, green: 0.352, blue: 0.561)
        let brocheIndigo   = Color(red: 0.176, green: 0.243, blue: 0.533)
        let brocheDeepBlue = Color(red: 0.066, green: 0.215, blue: 0.490)
    }
}

extension LinearGradient {
    /// The app's signature dusk gradient, bottom to top.
    static let broche = LinearGradient(
        gradient: Gradient(colors: [
            Color.theme.brocheNavy, Color.theme.brocheRose, Color.theme.brocheCoral,
            Color.theme.brocheMauve, Color.theme.brocheIndigo, Color.theme.brocheDeepBlue
        ]),
        startPoint: .bottom, endPoint: .top
    )

    /// A softened version for a top-edge "horizon" wash — use at low opacity.
    static let brocheHorizon = LinearGradient(
        gradient: Gradient(colors: [
            Color.theme.brocheRose.opacity(0.35),
            Color.theme.brocheCoral.opacity(0.18),
            .clear
        ]),
        startPoint: .top, endPoint: .bottom
    )

    /// For borders/strokes — a thin, legible version of the brand gradient.
    static let brocheStroke = LinearGradient(
        gradient: Gradient(colors: [Color.theme.brocheRose, Color.theme.brocheCoral, Color.theme.brocheMauve]),
        startPoint: .leading, endPoint: .trailing
    )
}
