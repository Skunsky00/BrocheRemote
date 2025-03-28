//
//  UploadPostSearchViewModel.swift
//  Broche
//
//  Created by Jacob Johnson on 7/19/23.
//

import Foundation
import MapKit

class UploadPostSearchViewModel: NSObject, ObservableObject {
    @Published var results = [MKLocalSearchCompletion]()
    @Published var queryFragment: String = "" {
        didSet {
            searchCompleter.queryFragment = queryFragment
        }
    }
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
    }
    
    func selectLocation(_ localSearch: MKLocalSearchCompletion) {
        // Additional logic if needed (e.g., refine location)
    }
}

extension UploadPostSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
    }
}

