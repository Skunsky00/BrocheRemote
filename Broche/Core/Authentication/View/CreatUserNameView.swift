//
//  CreatUserNameView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct CreatUserNameView: View {
    @EnvironmentObject var viewModel: RegistrationViewModel
    @State private var showCreatePasswordView = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.cyan, Color.teal, Color.green]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Creat Username")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                Text("Pick a username for your new account. You can always change it later.")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                ZStack(alignment: .trailing) {
                    TextField("Username", text: $viewModel.username)
                        .modifier(BrocheTextFieldModifier())
                        .padding(.top)
                        .autocapitalization(.none)

                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.trailing, 40)
                            .padding(.top, 14)
                    }
                }
                
                Button {
                    Task {
                        try await viewModel.validateUsername()
                    }
                } label: {
                    Text("Next")
                        .modifier(TextFieldModifier())
                }
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                
                Spacer()
            }
            .onReceive(viewModel.$usernameIsValid, perform: { usernameIsValid in
                if usernameIsValid {
                    self.showCreatePasswordView.toggle()
                }
            })
            .navigationDestination(isPresented: $showCreatePasswordView, destination: {
                CreatePasswordView()
            })
            .onAppear {
                showCreatePasswordView = false
                viewModel.usernameIsValid = false
            }
        }
    }
}

extension CreatUserNameView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !viewModel.username.isEmpty
    }
}


struct CreatUserNameView_Previews: PreviewProvider {
    static var previews: some View {
        CreatUserNameView()
            .environmentObject(RegistrationViewModel())

    }
}
