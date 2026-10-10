//
//  ShareViewController.swift
//  BrocheShare
//
//  Created by Jacob Johnson on 10/7/26.
//



// ShareViewController.swift  (BrocheShare target ONLY)
import UIKit
import SwiftUI
import FirebaseCore
import FirebaseAuth
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let viewModel = ShareViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        showUI()   // show the spinner right away

        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        try? Auth.auth().useUserAccessGroup("5K8U9AH5WN.com.brochetravel.broche.shared")

        Task {
            let shared = await extractSharedContent()
            await viewModel.begin(url: shared.url, caption: shared.text)
        }
    }

    private func showUI() {
        let root = ShareView(
            viewModel: viewModel,
            onDone: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            },
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: NSError(domain: "broche", code: 0))
            }
        )
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func extractSharedContent() async -> (url: URL?, text: String?) {
        var url: URL?
        var text: String?
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        for item in items {
            for provider in item.attachments ?? [] {
                if url == nil, provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let result = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                    url = result
                }
                if text == nil, provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let result = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                    text = result
                }
            }
        }
        return (url, text)
    }
}
