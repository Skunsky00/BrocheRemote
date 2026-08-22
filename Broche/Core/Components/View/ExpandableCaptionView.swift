//
//  ExpandableCaptionText.swift
//  Broche
//
//  Created by Jacob Johnson on 8/22/26.
//

import SwiftUI

struct ExpandableCaptionText: View {
    let username: String
    let caption: String
    var textColor: Color = .primary
    var font: Font = .subheadline
    var collapsedLineLimit: Int = 2
    var onShowMore: (() -> Void)? = nil

    @State private var isExpanded = false
    @State private var isTruncated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if username.isEmpty {
                    Text(caption)
                } else {
                    Text(username).fontWeight(.semibold) + Text(" " + caption)
                }
            }
            .font(font)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, alignment: .leading)   // NEW
            .lineLimit(isExpanded ? nil : collapsedLineLimit)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .task(id: caption) {
                            isTruncated = checkTruncation(width: geo.size.width)
                        }
                }
            )

            if isTruncated {
                Button {
                    if let onShowMore {
                        onShowMore()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(textColor.opacity(0.8))
                }
            }
        }
    }

    private func checkTruncation(width: CGFloat) -> Bool {
        let fullText = username.isEmpty ? caption : username + " " + caption   // CHANGED
        let uiFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let attributes: [NSAttributedString.Key: Any] = [.font: uiFont]
        let boundingRect = (fullText as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
        let lineHeight = uiFont.lineHeight
        let actualLines = ceil(boundingRect.height / lineHeight)
        return actualLines > CGFloat(collapsedLineLimit)
    }
}

struct CaptionBlock: View {
    let username: String
    let caption: String
    var textColor: Color = .primary
    var font: Font = .subheadline
    var collapsedLineLimit: Int = 2
    var expandedMaxHeight: CGFloat = 100

    @State private var isExpanded = false
    @State private var isTruncated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isExpanded {
                ScrollView {
                    captionText
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxHeight: expandedMaxHeight)
            } else {
                captionText
                    .lineLimit(collapsedLineLimit)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .task(id: caption) {
                                    isTruncated = checkTruncation(width: geo.size.width)
                                }
                        }
                    )
            }

            if isTruncated {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var captionText: some View {
        (
            Text(username).fontWeight(.semibold)
            + Text(" " + caption)
        )
        .font(font)
        .foregroundStyle(textColor)
    }

    private func checkTruncation(width: CGFloat) -> Bool {
        let fullText = username + " " + caption
        let uiFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let boundingRect = (fullText as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: uiFont],
            context: nil
        )
        let actualLines = ceil(boundingRect.height / uiFont.lineHeight)
        return actualLines > CGFloat(collapsedLineLimit)
    }
}
