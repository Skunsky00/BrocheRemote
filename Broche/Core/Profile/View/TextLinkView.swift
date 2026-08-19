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
        let textView = NonScrollingTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = .link
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        textView.linkTextAttributes = [
            .foregroundColor: linkColor
        ]
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString(text: text, linkColor: linkColor)
    }

    // CHANGED — no more HTML parsing, no more NSException risk
    private func attributedString(text: String, linkColor: UIColor) -> NSAttributedString {
        let mutable = NSMutableAttributedString(
            string: text,
            attributes: [.foregroundColor: UIColor.label]
        )

        // Manually detect URLs (and let dataDetectorTypes handle making them tappable)
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                mutable.addAttribute(.foregroundColor, value: linkColor, range: match.range)
            }
        }

        return mutable
    }

    class Coordinator: NSObject, UITextViewDelegate {
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            UIApplication.shared.open(URL)
            return false
        }
    }
}

private class NonScrollingTextView: UITextView {
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        // no-op — prevents auto-scroll bubbling to an ancestor scroll view
    }
}
