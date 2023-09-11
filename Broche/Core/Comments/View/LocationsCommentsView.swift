//
//  LocationsCommentsView.swift
//  Broche
//
//  Created by Jacob Johnson on 9/8/23.
//

import SwiftUI

struct LocationsCommentsView: View {
    @State private var commentText = ""
    @StateObject var viewModel: LocationCommentViewModel
    
    init(location: Location, locationType: LocationType) {
        self._viewModel = StateObject(wrappedValue: LocationCommentViewModel(location: location, locationType: locationType))
    }
    var body: some View {
        VStack {
//            Text("Comments")
//                .font(.subheadline)
//                .fontWeight(.bold)
//                .padding(.top, 10)
//                .padding(.bottom, -20)
        
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(viewModel.comments) { comment in
                        LocationCommentCell(comment: comment)
                    }
                }
            }.padding(.top)
            
            CustomInputView(inputText: $commentText, placeholder: "Comment...", action: uploadComment)
        }
        .navigationTitle("Comments")
        .toolbar(.hidden, for: .tabBar)
    }
    
    func uploadComment() {
            // Check if the commentText is empty before uploading the comment
            guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }

            Task {
                await viewModel.uploadVisitedComment(commentText: commentText)
                commentText = ""
            }
        }
    
}


