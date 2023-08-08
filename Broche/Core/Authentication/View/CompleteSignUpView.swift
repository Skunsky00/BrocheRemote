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
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.015, green: 0.196, blue: 0.274),Color(red: 0.772, green: 0.274, blue: 0.388), Color(red: 1.0, green: 0.4078, blue: 0.4039), Color(red: 0.588, green: 0.352, blue: 0.5607), Color(red: 0.176, green: 0.243, blue: 0.533),Color(red: 0.066, green: 0.215, blue: 0.490)]), startPoint: .bottom, endPoint: .top)
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
