//
//  SettingsView.swift
//  Broche
//
//  Created by Jacob Johnson on 5/31/23.
//

import SwiftUI

enum SettingsItemModel: Int, Identifiable, Hashable, CaseIterable {
    case settings
    case yourActivity
    case yourPost
    case logout
    
    var title: String {
        switch self {
        case .settings:
            return "Settings"
        case .yourActivity:
            return "Your Activity"
        case .yourPost:
            return "Your Post"
        case .logout:
            return "Logout"
        }
    }
    
    var imageName: String {
        switch self {
        case .settings:
            return "gear"
        case .yourActivity:
            return "cursorarrow.click.badge.clock"
        case .yourPost:
            return "square.grid.2x2"
        case .logout:
            return "arrow.left.square"
        }
    }
    
    var id: Int { return self.rawValue }
}

struct SettingsView: View {
    @Binding var selectedOption: SettingsItemModel?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 32, height: 4)
                .foregroundColor(.gray)
                .padding()
                
            List {
                ForEach(SettingsItemModel.allCases) { model in
                    SettingsRowView(model: model)
                        .onTapGesture {
                            selectedOption = model
                            dismiss()
                        }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct SettingsRowView: View {
    let model: SettingsItemModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: model.imageName)
                .imageScale(.medium)
            
            Text(model.title)
                .font(.subheadline)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(selectedOption: .constant(nil))
    }
}
