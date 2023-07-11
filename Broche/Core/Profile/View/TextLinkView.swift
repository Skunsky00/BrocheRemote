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
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = .link
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
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
            mutableAttributedString.addAttribute(.foregroundColor, value: linkColor, range: NSRange(location: 0, length: attributedString.length))
            return mutableAttributedString
        } catch {
            print("Error creating attributed string: \(error)")
            return nil
        }
    }
}
