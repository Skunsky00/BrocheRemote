//
//  PrivacyView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/13/23.
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Broche does not currently have any privay settings. They will be added shortly in the future :)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Spacer()
        }
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyView()
    }
}
