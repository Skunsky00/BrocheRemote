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
    private let searchCompleter = MKLocalSearchCompleter()
    var queryFragment: String = "" {
        didSet {
            searchCompleter.queryFragment = queryFragment
        }
    }
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.queryFragment = queryFragment
    }
    
    func selectLocation(_ localSearch: MKLocalSearchCompletion) {
        // Handle selected location
    }
}

extension UploadPostSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
    }
}
