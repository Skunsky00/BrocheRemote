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
            LinearGradient(gradient: Gradient(colors: [Color(red: 1.0, green: 0.4, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.1), Color(red: 1.0, green: 0.7, blue: 0.3), Color(red: 0.8, green: 0.3, blue: 0.7)]), startPoint: .bottom, endPoint: .top)
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
        return !viewModel.email.isEmpty
        && viewModel.email.contains("@")
        && viewModel.email.contains(".")
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
