//
//  ResetPasswordView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/4/23.
//

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var mode
    @Binding private var email: String
    @State private var resetLinkSent = false
    
    
    init(email: Binding<String>) {
        self._email = email
    }
    
    var color = #colorLiteral(red: 0.1698683487, green: 0.3265062064, blue: 0.74163749, alpha: 1)
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.015, green: 0.196, blue: 0.274),Color(red: 0.772, green: 0.274, blue: 0.388), Color(red: 1.0, green: 0.4078, blue: 0.4039), Color(red: 0.588, green: 0.352, blue: 0.5607), Color(red: 0.176, green: 0.243, blue: 0.533),Color(red: 0.066, green: 0.215, blue: 0.490)]), startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
            VStack {
                
                Text("Broche")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 80)
            
                
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .modifier(BrocheTextFieldModifier())
                        
                }
                
                // sign in
                Button(action: {
                    viewModel.resetPassword(withEmail: email)
                }, label: {
                    Text("Send Reset Password Link")
                        .modifier(TextFieldModifier())
                        .padding()
                })
                
                Spacer()
                
                Button(action: {mode.wrappedValue.dismiss()}, label: {
                    HStack{
                        Text("Already have an account?")
                        
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .font(.footnote)
                })
                
                
            }
            .padding(.top, -16)
        }
        .onReceive(viewModel.$didSendResetPasswordLink) { value in
                    if value {
                        resetLinkSent = true // Update the @State variable
                    }
                }
                .onChange(of: resetLinkSent) {
                    if resetLinkSent {
                        self.mode.wrappedValue.dismiss() // Dismiss the view
                    }
                }
    }
}


