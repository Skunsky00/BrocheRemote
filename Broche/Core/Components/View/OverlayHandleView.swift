//
//  OverlayHandleView.swift
//  Broche
//
//  Created by Jacob Johnson on 7/31/26.
//

import SwiftUI

struct OverlayHandle: View {
    var body: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 36, height: 5)
            .padding(.vertical, 6)
            .contentShape(Rectangle()) // makes the whole padded area tappable, not just the visible pill
    }
}
