//
//  LocationSearchActivationView2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI

import SwiftUI

struct LocationSearchActivationView2: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient.broche)
                    .frame(width: 34, height: 34)
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text("Where to next?")
                .font(.system(.body, design: .serif))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(LinearGradient.brocheStroke.opacity(0.5), lineWidth: 1.25)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.12), radius: 10, x: 0, y: 4)
        .onboardingTarget(.searchBar)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.2), .green.opacity(0.2)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        VStack {
            LocationSearchActivationView2()
                .padding(.horizontal)
            Spacer()
        }
        .padding(.top, 60)
    }
}
