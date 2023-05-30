//
//  LoginView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    var color = #colorLiteral(red: 0.1698683487, green: 0.3265062064, blue: 0.74163749, alpha: 1)
    
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
                        TextField("Enter your email", text: $viewModel.email)
                            .autocapitalization(.none)
                            .modifier(BrocheTextFieldModifier())
                        
                        SecureField("Enter your password", text: $viewModel.password)
                            .modifier(BrocheTextFieldModifier())
                    }
                    
                    Button {
                        print("Show forgot password")
                    } label: {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.top)
                            .padding(.trailing, 33)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Button {
                        Task { try await viewModel.signIn() }
                    } label: {
                        Text("Login")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(width: 360, height: 44)
                            .foregroundColor(.white)
                            .background(Color(color))
                            .cornerRadius(8)
                    }
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
