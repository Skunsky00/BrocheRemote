//
//  LocationSearchActivationView2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI

struct LocationSearchActivationView2: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(.blue)
            Text("Search or tap map")
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
                .shadow(radius: 4)
        )
        .onboardingTarget(.searchBar)   // NEW
    }
}
