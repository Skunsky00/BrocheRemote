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
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3)
                .foregroundStyle(.blue)
            Text("Search or tap map")
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.9))
                .shadow(radius: 4)
        )
    }
}
