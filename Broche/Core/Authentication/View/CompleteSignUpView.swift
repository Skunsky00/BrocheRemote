//
//  CompleteSignUpView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/18/23.
//

import SwiftUI

struct CompleteSignUpView: View {
    @EnvironmentObject var viewModel: RegistrationViewModel
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.cyan, Color.teal, Color.green]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                Text("Welcome to Broche, \(viewModel.username)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                    .multilineTextAlignment(.center)
                
                Text("Click below to complete registration and start using Broche")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                
                
                Button {
                    Task { try await viewModel.createUser() }
                } label: {
                    Text("Complete Sign Up")
                        .modifier(TextFieldModifier())
                }
                .padding(.vertical)
                
                Spacer()
            }
        }
    }
}

struct CompleteSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        CompleteSignUpView()
            .environmentObject(RegistrationViewModel())
    }
}
