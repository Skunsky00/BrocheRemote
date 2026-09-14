//
//  LocationSearchResultCell2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI

struct LocationSearchResultCell2: View {
    let title: String
    let subtitle: String
    var isPointOfInterest: Bool = false
 
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isPointOfInterest ? AnyShapeStyle(LinearGradient.broche) : AnyShapeStyle(Color(.tertiarySystemFill)))
                    .frame(width: 38, height: 38)
                Image(systemName: isPointOfInterest ? "mappin" : "circle.fill")
                    .font(.system(size: isPointOfInterest ? 15 : 6, weight: .semibold))
                    .foregroundStyle(isPointOfInterest ? .white : Color.secondary)
            }
 
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
 
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
