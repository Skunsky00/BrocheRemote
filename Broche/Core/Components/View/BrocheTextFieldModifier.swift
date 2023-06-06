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

struct TextFieldModifier: ViewModifier {
    var color = #colorLiteral(red: 0.1698683487, green: 0.3265062064, blue: 0.74163749, alpha: 1)
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .fontWeight(.semibold)
            .frame(width: 360, height: 44)
            .foregroundColor(.white)
            .background(Color(color))
            .cornerRadius(8)
    }
}
