//
//  CreatePasswordView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct CreatePasswordView: View {
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.cyan, Color.teal, Color.green]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Creat a Password")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                Text("Your password must be at least 6 charaters in length")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                SecureField("Password", text: $viewModel.password)
                    .modifier(BrocheTextFieldModifier())
                    .padding(.top)
                
                NavigationLink {
                    CompleteSignUpView()
                        .navigationBarBackButtonHidden()
                } label: {
                    Text("Next")
                        .modifier(TextFieldModifier())
                        .padding(.top)
                }
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                
                Spacer()
            }
        }
    }
}

extension CreatePasswordView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.password.isEmpty && viewModel.password.count > 5
    }
}


struct CreatePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePasswordView()
        
    }
}
