//
//  ConversationsView.swift
//  Broche
//
//  Created by Jacob Johnson on 6/10/23.
//

import SwiftUI

struct ConversationsView: View {
    @State var isShowingNewMessageView = false
    @State var showChat = false
    @State var user: User?
    @StateObject var viewModel = ConversationsViewModel()
    
    var body: some View {
        ScrollView {
            if viewModel.recentMessages.isEmpty {
                VStack {
                    Spacer()
                    Text("You have no messages")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack {
                    ForEach(viewModel.recentMessages) { message in
                        NavigationLink {
                            if let user = message.user {
                                ChatView(user: user)
                            }
                        } label: {
                            ConversationCell(message: message)
                        }
                    }
                }
                .padding()
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingNewMessageView, content: {
            NewMessageView(show: $isShowingNewMessageView, startChat: $showChat, user: $user)
        })
        .toolbar(content: {
            Button {
                isShowingNewMessageView.toggle()
            } label: {
                Image(systemName: "square.and.pencil")
                    .imageScale(.large)
            }
        })
        .onAppear {
            viewModel.loadData()
            print("🔔 ConversationsView onAppear - recentMessages count: \(viewModel.recentMessages.count)")
        }
        .navigationDestination(isPresented: $showChat) {
            if let user = user {
                ChatView(user: user)
            }
        }
    }
}

struct ConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsView()
    }
}

