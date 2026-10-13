//
//  TextEditingView.swift
//  Broche
//
//  Created by Jacob Johnson on 10/12/26.
//

import SwiftUI

struct TextEditingView: View {
    @ObservedObject var editor: MediaEditorViewModel
    @FocusState private var focused: Bool

    private let colors: [Color] = [.white, .black, .yellow, .orange, .red, .pink, .blue, .green]

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture { editor.finishEditing() }

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Done") { editor.finishEditing() }
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                HStack {
                    Slider(value: $editor.draft.fontSize, in: 20...80)
                        .frame(width: 180)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 30, height: 180)
                        .tint(.white)

                    TextField("", text: $editor.draft.text, axis: .vertical)
                        .font(editor.draft.style.font(size: editor.draft.fontSize))
                        .foregroundStyle(editor.draft.color)
                        .multilineTextAlignment(.center)
                        .focused($focused)
                        .tint(.white)

                    Color.clear.frame(width: 30)
                }
                .padding(.horizontal, 8)
                .frame(maxHeight: .infinity)

                fontRow
                colorRow
            }
        }
        .onAppear { focused = true }
    }

    private var fontRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TextStyleOption.allCases, id: \.self) { style in
                    let selected = editor.draft.style == style
                    Button {
                        editor.draft.style = style
                    } label: {
                        Text(style.label)
                            .font(style.font(size: 16))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected ? Color.white : Color.white.opacity(0.2))
                            .foregroundStyle(selected ? .black : .white)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private var colorRow: some View {
        HStack(spacing: 12) {
            ForEach(colors, id: \.self) { color in
                Button {
                    editor.draft.color = color
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: editor.draft.color == color ? 3 : 1))
                }
            }
        }
        .padding(.bottom, 10)
    }
}
