//
//  AddEmailView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct AddEmailView: View {
    @EnvironmentObject var viewModel: RegistrationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showCreatUserNameView = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.015, green: 0.196, blue: 0.274),Color(red: 0.772, green: 0.274, blue: 0.388), Color(red: 1.0, green: 0.4078, blue: 0.4039), Color(red: 0.588, green: 0.352, blue: 0.5607), Color(red: 0.176, green: 0.243, blue: 0.533),Color(red: 0.066, green: 0.215, blue: 0.490)]), startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Add your email")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                Text("You'll use this email to sign in to your account")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                ZStack(alignment: .trailing) {
                    TextField("Email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .modifier(BrocheTextFieldModifier())
                        .padding(.top)
                        .autocapitalization(.none)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.trailing, 40)
                            .padding(.top, 14)
                    }
                    
                    if viewModel.emailValidationFailed {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.systemRed))
                            .padding(.trailing, 40)
                            .padding(.top, 14)
                    }
                }
                
                if viewModel.emailValidationFailed {
                    Text("This email is already in use. Please login or try again.")
                        .font(.caption)
                        .foregroundColor(Color(.systemRed))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                }
                
                Button {
                    Task {
                        try await viewModel.validateEmail()
                    }
                } label: {
                    Text("Next")
                        .modifier(TextFieldModifier())
                }
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            .onReceive(viewModel.$emailIsValid, perform: { emailIsValid in
                if emailIsValid {
                    self.showCreatUserNameView.toggle()
                }
            })
            .navigationDestination(isPresented: $showCreatUserNameView, destination: {
                CreatUserNameView()
            })
            
            .onAppear {
                showCreatUserNameView = false
                viewModel.emailIsValid = false
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                        .onTapGesture {
                            presentationMode.wrappedValue.dismiss()
                        }
                }
            }
        }
    }
}

extension AddEmailView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        guard !viewModel.email.isEmpty else { return false }
        
        // Check if the email contains one of the allowed domain endings
        let allowedDomainEndings = [".com", ".gov", ".edu", ".net", ".int", ".mil", ".org", ".arpa"]
        let emailComponents = viewModel.email.split(separator: "@")
        
        if emailComponents.count == 2 {
            let domain = String(emailComponents[1])
            return allowedDomainEndings.contains(where: { domain.hasSuffix($0) })
        }
        
        return false
    }
}


struct AddEmailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddEmailView()
                .environmentObject(RegistrationViewModel())
        }
    }
}
