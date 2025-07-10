//
//  TextLinkView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/28/23.
//

import Foundation
import SwiftUI

struct TextLinkView: UIViewRepresentable {
    let text: String
    let linkColor: UIColor

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = .link
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.linkTextAttributes = [
            .foregroundColor: linkColor
        ]
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString(text: text, linkColor: linkColor)
    }

    private func attributedString(text: String, linkColor: UIColor) -> NSAttributedString? {
        guard let data = text.data(using: .utf16) else { return nil }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf16.rawValue
        ]

        do {
            let attributedString = try NSAttributedString(
                data: data,
                options: options,
                documentAttributes: nil
            )

            let mutable = NSMutableAttributedString(attributedString: attributedString)
            mutable.addAttribute(.foregroundColor, value: linkColor, range: NSRange(location: 0, length: mutable.length))
            return mutable

        } catch {
            print("❌ Failed to create attributed string from HTML: \(error)")
            return NSAttributedString(string: text) // ← fallback to plain string
        }
    }


    class Coordinator: NSObject, UITextViewDelegate {
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false
        }
    }
}

