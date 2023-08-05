//
//  CustomScrollView.swift
//  Broche
//
//  Created by Jacob Johnson on 8/3/23.
//

import Foundation
import SwiftUI
import UIKit

struct CustomScrollView: UIViewRepresentable {
    var posts: [Post]
    @Binding var currentVisiblePost: Post?
    
    func makeCoordinator() -> Coordinator {
        return CustomScrollView.Coordinator(view: self)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * CGFloat(posts.count))
        scrollView.delegate = context.coordinator
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        for (index, view) in uiView.subviews.enumerated() {
            view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height * CGFloat(index), width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
    }
    
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var view: CustomScrollView
        var currentVisiblePost: Post?
        
        init(view: CustomScrollView) {
            self.view = view
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let index = Int(scrollView.contentOffset.y / UIScreen.main.bounds.height)
            if index >= 0 && index < view.posts.count {
                currentVisiblePost = view.posts[index] // Update the currentVisiblePost based on the scroll position
                print("Currently visible post: \(currentVisiblePost?.id ?? "N/A")")// Print the post's ID as an int
            }
        }
    }
}




