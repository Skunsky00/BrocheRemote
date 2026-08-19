//
//  SearchBar.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            TextField("Search...", text: $text)
                .font(.body)
                .focused($isFocused)
                .padding(.vertical, 12)
                .padding(.horizontal, 36)
                .background(Color(colorScheme == .dark ? .systemGray4 : .systemGray6))
                .cornerRadius(12)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.body)
                            .foregroundColor(Color.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 12)
                    }
                )

            if isEditing {
                Button(action: {
                    isFocused = false
                    isEditing = false
                    text = ""
                }, label: {
                    Text("Cancel")
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                })
                .padding(.trailing, 8)
                .transition(.move(edge: .trailing))
            }
        }
        .onChange(of: isFocused) { newValue in
            if newValue {
                isEditing = true
            }
        }
    }
}




struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(text: .constant("Search..."), isEditing: .constant(true))
    }
}
