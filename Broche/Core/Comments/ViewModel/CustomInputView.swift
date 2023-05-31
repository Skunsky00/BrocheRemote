//
//  CustomInputView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import SwiftUI

struct CustomInputView: View {
    @Binding var inputText: String
    let placeholder: String
    
    var action: () -> Void
    
    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(Color(.separator))
                .frame(width: UIScreen.main.bounds.width, height: 0.75)
                .padding(.bottom, 8)
            
            HStack {
                TextField(placeholder, text: $inputText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.body)
                    .frame(minHeight: 30)
                
                Button(action: action) {
                    Text("Send")
                        .bold()
                        .foregroundColor(.black)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal)
        }
    }
}
