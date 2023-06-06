//
//  LoginView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @StateObject var viewModel = LoginViewModel()
    @EnvironmentObject var registrationViewModel: RegistrationViewModel
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.cyan, Color.teal, Color.green]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack {
                    
                    Spacer()
                    
                    //logo name
                    Text("Broche")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    //text fields
                    VStack {
                        TextField("Enter your email", text: $email)
                            .autocapitalization(.none)
                            .modifier(BrocheTextFieldModifier())
                        
                        SecureField("Enter your password", text: $password)
                            .modifier(BrocheTextFieldModifier())
                    }
                    
                    NavigationLink(
                        destination: ResetPasswordView(email: $email)
                            .environmentObject(authViewModel)
                        ,
                        label: {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .padding(.top)
                                .padding(.trailing, 28)
                        })
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Button {
                        Task { try await viewModel.signIn(withEmail: email, password: password) }
                    } label: {
                        Text("Login")
                            .modifier(TextFieldModifier())
                    }
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1.0 : 0.5)
                    .padding(.vertical)
                    
                    Spacer()
                    
                    Divider()
                    
                    NavigationLink {
                        AddEmailView()
                            .navigationBarBackButtonHidden()
                    } label: {
                        HStack(spacing: 3) {
                            Text("Dont have an account?")
                            
                            Text("Sign up")
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                        .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
    }
}


extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        && password.count > 5
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(RegistrationViewModel())
    }
}
