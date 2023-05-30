//
//  BrocheTextFieldModifier.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct BrocheTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
        .font(.subheadline)
        .padding(12)
        .background(Color(.init(white: 1, alpha: 0.15)))
        .cornerRadius(10)
        .padding(.horizontal, 24)
    }
}
