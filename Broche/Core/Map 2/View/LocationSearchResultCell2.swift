//
//  LocationSearchResultCell2.swift
//  Broche
//
//  Created by Jacob Johnson on 8/13/25.
//

import SwiftUI

struct LocationSearchResultCell2: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .foregroundStyle(.blue)
                .accentColor(.white)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.body)
                Text(subtitle).font(.system(size: 15)).foregroundStyle(.gray)
                Divider()
            }
            .padding(.leading, 8)
            .padding(.vertical, 8)
        }
        .padding(.leading)
    }
}
