//
//  PasswordField.swift
//  Broche
//
//  Created by Jacob Johnson on 10/12/26.
//

import SwiftUI

struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .modifier(BrocheTextFieldModifier())
            
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
                    .padding(.trailing, 36)
            }
        }
    }
}
