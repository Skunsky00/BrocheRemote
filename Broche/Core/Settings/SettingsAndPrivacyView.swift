//
//  SettingsAndPrivacyView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI

enum SettingsPrivacyModel: Int, Identifiable, Hashable, CaseIterable {
    case account
    case privacy
    
    var title: String {
        switch self {
        case .account:
            return "Account"
        case .privacy:
            return "Privacy"
        }
    }
    
    var imageName: String {
        switch self {
        case .account:
            return "person"
        case .privacy:
            return "hand.raised.circle.fill"
        }
    }
    
    var id: Int { return self.rawValue }
}

struct SettingsAndPrivacyView: View {
    let user: User
    @Binding var selectedOption: SettingsPrivacyModel?
    @State private var showDetail = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SettingsPrivacyModel.allCases) { model in
                    SettingsPrivacyRowView(model: model)
                        .onTapGesture {
                            selectedOption = model
                            showDetail = true // Show the detail view when tapped
                        }
                }
            }
            .listStyle(PlainListStyle())
            .navigationDestination(isPresented: $showDetail) {
                if let option = selectedOption {
                    switch option {
                    case .account:
                        AccountView(viewModel: AccountViewModel(user: user))
                            .navigationTitle("Account")
                    case .privacy:
                        PrivacyView()
                            .navigationTitle("Privacy")
                    }
                }
            }
        }
    }
}



struct SettingsPrivacyRowView: View {
    let model: SettingsPrivacyModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: model.imageName)
                .imageScale(.medium)
            
            Text(model.title)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsAndPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAndPrivacyView(user: User.MOCK_USERS[0], selectedOption: .constant(nil))
    }
}
